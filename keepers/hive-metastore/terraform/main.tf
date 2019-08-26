terraform {
  required_version = "~> 0.12"
}

resource "google_project_service" "storage-component" {
  project                    = var.project
  service                    = "storage-component.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_compute_http_health_check" "hms" {
  name    = "hms-${var.environment_name}-hc"
  project = var.project

  check_interval_sec  = "10"
  timeout_sec         = "10"
  healthy_threshold   = "1"
  unhealthy_threshold = "5"

  # TODO: Change for better health check location
  port         = var.jmx_port
  request_path = "/metrics"
}

resource "google_compute_target_pool" "hms" {
  name = "hms-${var.environment_name}-pool"

  project          = var.project
  region           = var.region
  session_affinity = "NONE"
  health_checks    = [google_compute_http_health_check.hms.name]
}

resource "google_compute_health_check" "hms" {
  name    = "hms-${var.environment_name}-internal-hc"
  count   = (var.lb_schema == "INTERNAL" ? 1 : 0)
  project = var.project

  check_interval_sec  = "10"
  timeout_sec         = "10"
  healthy_threshold   = "1"
  unhealthy_threshold = "5"

  # TODO: Change for better health check location
  http_health_check {
    port         = var.jmx_port
    request_path = "/metrics"
  }
}

resource "google_compute_region_backend_service" "hms" {
  name  = "hms-${var.environment_name}-internal-lb"
  count = (var.lb_schema == "INTERNAL" ? 1 : 0)

  project = var.project

  session_affinity = "NONE"
  health_checks    = [google_compute_health_check.hms[0].self_link]

  backend {
    group = var.zonal ? module.hms.instance_group : module.hms.region_instance_group
  }

}

resource "google_compute_forwarding_rule" "hms" {
  name    = (var.instance_group_lb_name != "" ? var.instance_group_lb_name : "hms-${var.environment_name}-lb")
  project = var.project
  region  = var.region

  load_balancing_scheme = var.lb_schema
  // External
  target     = (var.lb_schema == "EXTERNAL" ? google_compute_target_pool.hms.self_link : null)
  port_range = (var.lb_schema == "EXTERNAL" ? var.http_port : null)
  // Internal
  backend_service = (var.lb_schema == "INTERNAL" ? google_compute_region_backend_service.hms[0].self_link : null)
  all_ports       = (var.lb_schema == "INTERNAL" ? true : null)
  network         = (var.lb_schema == "INTERNAL" ? var.network : null)
  subnetwork      = (var.lb_schema == "INTERNAL" ? var.subnetwork : null)
}

# Allow internal subnet connections to certain ports
resource "google_compute_firewall" "hms" {
  name = "hms-${var.environment_name}"

  project = var.project
  network = var.network

  allow {
    protocol = "tcp"
    ports    = concat([var.http_port, var.jmx_port], var.subnet_ports)
  }

  source_ranges = [var.subnetwork_range]
  target_tags   = ["allow-hms-${var.environment_name}-subnet"]
}

data "template_file" "additional_hosts" {
  template = file(format("%s/templates/additional_hosts", path.module))

  vars = {
    HOSTS = join("\n", var.additional_hosts)
  }
}

data "local_file" "log_config" {
  filename = format("%s/templates/hive-log4j2.properties", path.module)
}

data "template_file" "hivemetastore_site_xml" {
  template = file(format("%s/templates/hivemetastore-site.xml", path.module))

  vars = {
    METASTORE_DB_HOST       = var.database_host
    METASTORE_DB_PORT       = var.database_port
    METASTORE_DB_NAME       = var.database_name
    METASTORE_DB_USER       = var.database_user
    METASTORE_DB_PASSWORD   = var.database_password
    METASTORE_WAREHOUSE_DIR = var.warehouse_dir
  }
}

data "archive_file" "hms_config" {
  type        = "zip"
  output_path = "${path.module}/dist/hms_config_${var.environment_name}.zip"

  source {
    content  = data.template_file.additional_hosts.rendered
    filename = "additional_hosts"
  }
  source {
    content  = data.local_file.log_config.content
    filename = "hive-log4j2.properties"
  }
  source {
    content  = data.template_file.hivemetastore_site_xml.rendered
    filename = "hivemetastore-site.xml"
  }
}

data "template_file" "bootstrap" {
  template = file(format("%s/templates/bootstrap.sh", path.module))

  vars = {
    ENABLE_CLOUD_SQL_PROXY   = var.cloudsql_instance_connection_enabled
    INSTANCE_CONNECTION_NAME = var.cloudsql_instance_connection_name
    GCS_CONFIG_BUCKET        = google_storage_bucket_object.hms_config.bucket
    GCS_CONFIG_OBJECT        = google_storage_bucket_object.hms_config.name
  }
}

resource "google_storage_bucket_object" "hms_config" {
  name   = "hms_${var.environment_name}_${data.archive_file.hms_config.output_md5}.zip"
  bucket = var.gcs_bucket
  source = data.archive_file.hms_config.output_path
}

module "hms" {
  # source  = "GoogleCloudPlatform/managed-instance-group/google"
  # version = "1.1.15"
  # Using Fork as original is incompatible with the Google >= 2.0 provider
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  source = "git::https://github.com/rchukh/terraform-google-managed-instance-group.git?ref=terraform_0.12"

  name = (var.instance_group_name != "" ? var.instance_group_name : "hms-${var.environment_name}")

  size = var.instance_group_size

  project    = var.project
  region     = var.region
  zone       = var.zone
  network    = var.network
  subnetwork = var.subnetwork

  compute_image = var.instance_image
  machine_type  = var.instance_type
  disk_type     = var.instance_disk_type

  startup_script = (var.custom_bootstrap != "" ? var.custom_bootstrap : data.template_file.bootstrap.rendered)

  service_account_scopes = var.service_account_scopes
  service_port           = var.http_port
  service_port_name      = "http"
  # Use autohealing in case startup script fails due to failed connection to database
  http_health_check = true
  hc_initial_delay  = "90"
  # TODO: Add support for passing the existing health check to the terraform-google-managed-instance-group
  hc_timeout             = google_compute_http_health_check.hms.timeout_sec
  hc_unhealthy_threshold = google_compute_http_health_check.hms.unhealthy_threshold
  hc_port                = google_compute_http_health_check.hms.port
  hc_path                = google_compute_http_health_check.hms.request_path

  target_pools       = [google_compute_target_pool.hms.self_link]
  target_tags        = google_compute_firewall.hms.target_tags
  wait_for_instances = true

  zonal         = var.zonal
  update_policy = var.instance_group_update_policy

  distribution_policy_zones = var.distribution_policy_zones
}