terraform {
  required_version = "~> 0.12"
}

resource "google_project_service" "storage-component" {
  project                    = var.project
  service                    = "storage-component.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_compute_http_health_check" "trino" {
  name    = "trino-${var.environment_name}-hc"
  project = var.project

  check_interval_sec  = "10"
  timeout_sec         = "10"
  healthy_threshold   = "1"
  unhealthy_threshold = "5"

  port         = var.http_port
  request_path = "/v1/status"
}

resource "google_compute_target_pool" "trino" {
  name = "trino-${var.environment_name}-pool"

  project          = var.project
  region           = var.region
  session_affinity = "NONE"
  health_checks    = [google_compute_http_health_check.trino.name]
}

resource "google_compute_forwarding_rule" "trino" {
  name = (var.coordinator_group_lb_name != "" ? var.coordinator_group_lb_name : "trino-${var.environment_name}-lb")

  project               = var.project
  region                = var.region
  target                = google_compute_target_pool.trino.self_link
  load_balancing_scheme = var.coordinator_group_lb_schema
  port_range            = var.http_port
}

# TODO: Set source_ranges to internal network in case of Internal LB 
resource "google_compute_firewall" "trino-lb-fw" {
  name = "trino-${var.environment_name}-fr-fw"

  project = var.project
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [module.coordinator_group.service_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-trino-${var.environment_name}-coordinator"]
}

# Allow communications between coordinator and workers
resource "google_compute_firewall" "trino" {
  name = "trino-${var.environment_name}-communications"

  project = var.project
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [var.http_port]
  }

  source_ranges = [var.subnetwork_range]
  target_tags   = ["allow-trino-${var.environment_name}"]
}

# Allow inside of subnet
resource "google_compute_firewall" "trino_metrics" {
  name = "trino-${var.environment_name}-metrics"

  project = var.project
  network = var.network

  allow {
    protocol = "tcp"
    ports    = concat([var.jmx_port], var.subnet_ports)
  }

  source_ranges = [var.subnetwork_range]
  target_tags   = ["allow-trino-${var.environment_name}-metrics"]
}

data "template_file" "additional_hosts" {
  template = file(format("%s/templates/additional_hosts", path.module))

  vars = {
    HOSTS = join("\n", var.additional_hosts)
  }
}

data "template_file" "coordinator_config" {
  template = file(format("%s/templates/coordinator.config.tpl", path.module))

  vars = {
    # NOTE: Coordinator does not need to go through LB to its own location.
    COORDINATOR = "http://localhost:${var.http_port}"
    PORT        = var.http_port
  }
}

data "template_file" "coordinator_startup_script" {
  template = file(format("%s/templates/bootstrap.sh", path.module))

  vars = {
    ENV_NAME          = var.environment_name
    GCS_CONFIG_BUCKET = google_storage_bucket_object.coordinator_config.bucket
    GCS_CONFIG_OBJECT = google_storage_bucket_object.coordinator_config.name
  }
}

data "archive_file" "coordinator_config" {
  type        = "zip"
  output_path = "${path.module}/dist/coordinator_config_${var.environment_name}.zip"

  source {
    content  = data.template_file.additional_hosts.rendered
    filename = "additional_hosts"
  }
  source {
    content  = var.coordinator_config != "" ? var.coordinator_config : data.template_file.coordinator_config.rendered
    filename = "config.properties"
  }

  dynamic "source" {
    for_each = [for catalog in var.catalogs: {
      file_name        = catalog.file_name
      rendered_content = catalog.content
    }]
    content {
      content  = source.value.rendered_content
      filename = format("catalog/%s", source.value.file_name)
    }
  }
}

resource "google_storage_bucket_object" "coordinator_config" {
  name   = "trino_${var.environment_name}_${data.archive_file.coordinator_config.output_md5}.zip"
  bucket = var.gcs_bucket
  source = data.archive_file.coordinator_config.output_path
}

module "coordinator_group" {
  # source  = "GoogleCloudPlatform/managed-instance-group/google"
  # version = "1.1.15"
  # Using Fork as original is incompatible with the Google >= 2.0 provider
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  source = "git::https://github.com/rchukh/terraform-google-managed-instance-group.git?ref=terraform_0.12"

  name = (var.coordinator_group_name != "" ? var.coordinator_group_name : "trino-${var.environment_name}-coordinators")

  # Coordinator Pool is fixed to 1 (Trino specifics)
  # See: https://github.com/trinodb/trino/issues/391
  size = 1

  project    = var.project
  region     = var.region
  zone       = var.zone
  network    = var.network
  subnetwork = var.subnetwork

  compute_image = var.coordinator_image
  machine_type  = var.coordinator_type
  disk_type     = var.coordinator_disk_type

  startup_script = (var.coordinator_startup_script != "" ? var.coordinator_startup_script : data.template_file.coordinator_startup_script.rendered)

  service_account_scopes = var.service_account_scopes
  service_port           = var.http_port
  service_port_name      = "http"
  http_health_check      = false
  target_pools           = [google_compute_target_pool.trino.self_link]
  target_tags = setunion(
    google_compute_firewall.trino-lb-fw.target_tags,
    google_compute_firewall.trino.target_tags,
    google_compute_firewall.trino_metrics.target_tags
  )

  wait_for_instances = true
  update_policy      = var.coordinator_update_policy
}

data "template_file" "worker_config" {
  template = file(format("%s/templates/worker.config.tpl", path.module))

  vars = {
    COORDINATOR = "http://${google_compute_forwarding_rule.trino.ip_address}:${var.http_port}"
    PORT        = var.http_port
  }
}

data "template_file" "worker_startup_script" {
  template = file(format("%s/templates/bootstrap.sh", path.module))

  vars = {
    ENV_NAME          = var.environment_name
    GCS_CONFIG_BUCKET = google_storage_bucket_object.worker_config.bucket
    GCS_CONFIG_OBJECT = google_storage_bucket_object.worker_config.name
  }
}

data "archive_file" "worker_config" {
  type        = "zip"
  output_path = "${path.module}/dist/worker_config_${var.environment_name}.zip"

  source {
    content  = data.template_file.additional_hosts.rendered
    filename = "additional_hosts"
  }
  source {
    content  = var.worker_config != "" ? var.worker_config : data.template_file.worker_config.rendered
    filename = "config.properties"
  }
  dynamic "source" {
    for_each = [for catalog in var.catalogs: {
      file_name        = catalog.file_name
      rendered_content = catalog.content
    }]
    content {
      content  = source.value.rendered_content
      filename = format("catalog/%s", source.value.file_name)
    }
  }
}

resource "google_storage_bucket_object" "worker_config" {
  name   = "trino_${var.environment_name}_${data.archive_file.worker_config.output_md5}.zip"
  bucket = var.gcs_bucket
  source = data.archive_file.worker_config.output_path
}

module "worker_group" {
  # source  = "GoogleCloudPlatform/managed-instance-group/google"
  # version = "1.1.15"
  # Using Fork as original is incompatible with the Google >= 2.0 provider
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  source = "git::https://github.com/rchukh/terraform-google-managed-instance-group.git?ref=terraform_0.12"

  name = (var.worker_group_name != "" ? var.worker_group_name : "trino-${var.environment_name}-workers")

  size = var.worker_group_size

  project    = var.project
  region     = var.region
  zone       = var.zone
  network    = var.network
  subnetwork = var.subnetwork

  compute_image = var.worker_image
  machine_type  = var.worker_type
  disk_type     = var.worker_disk_type

  startup_script = (var.worker_startup_script != "" ? var.worker_startup_script : data.template_file.worker_startup_script.rendered)

  service_account_scopes = var.service_account_scopes
  service_port           = var.http_port
  service_port_name      = "http"
  http_health_check      = false
  target_pools           = []
  target_tags = setunion(
    google_compute_firewall.trino.target_tags,
    google_compute_firewall.trino_metrics.target_tags
  )

  wait_for_instances = true
  update_policy      = var.worker_update_policy
}
