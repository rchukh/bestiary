terraform {
  required_version = "~> 0.12"
}

resource "google_compute_http_health_check" "presto" {
  name = "presto-${var.environment_name}-hc"

  project      = var.project
  port         = var.http_port
  request_path = "/v1/status"
}

resource "google_compute_target_pool" "presto" {
  name = "presto-${var.environment_name}-pool"

  project          = var.project
  region           = var.region
  session_affinity = "NONE"
  health_checks    = [google_compute_http_health_check.presto.name]
}

resource "google_compute_forwarding_rule" "presto" {
  name = (var.coordinator_group_lb_name != "" ? var.coordinator_group_lb_name : "presto-${var.environment_name}-lb")

  project               = var.project
  region                = var.region
  target                = google_compute_target_pool.presto.self_link
  load_balancing_scheme = var.coordinator_group_lb_schema
  port_range            = var.http_port
}

# TODO: Set source_ranges to internal network in case of Internal LB 
resource "google_compute_firewall" "presto-lb-fw" {
  name = "presto-${var.environment_name}-fr-fw"

  project = var.project
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [module.coordinator_group.service_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-presto-${var.environment_name}-coordinator"]
}

# Allow communications between coordinator and workers
resource "google_compute_firewall" "presto" {
  name = "presto-${var.environment_name}-communications"

  project = var.project
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [var.http_port]
  }

  source_ranges = [var.subnetwork_range]
  target_tags   = ["allow-presto-${var.environment_name}"]
}

data "template_file" "coordinator_config" {
  template = file(format("%s/templates/coordinator.config.tpl", path.module))

  vars = {
    # NOTE: Coordinator does not need to go through LB to its own location.
    COORDINATOR = "http://localhost:${var.http_port}"
    PORT        = var.http_port
  }
}

data "template_file" "coordinator-startup-script" {
  template = file(format("%s/templates/startup.sh.tpl", path.module))

  vars = {
    ENV_NAME = var.environment_name

    PRESTO_CONFIG = (
      var.coordinator_config != "" ? var.coordinator_config
      : data.template_file.coordinator_config.rendered
    )
  }
}

module "coordinator_group" {
  # source  = "GoogleCloudPlatform/managed-instance-group/google"
  # version = "1.1.15"
  # Using Fork as original is incompatible with the Google >= 2.0 provider
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  source = "git::https://github.com/rchukh/terraform-google-managed-instance-group.git?ref=terraform_0.12"

  name = (var.coordinator_group_name != "" ? var.coordinator_group_name : "presto-${var.environment_name}-coordinators")

  # Coordinator Pool is fixed to 1 (Presto specifics) 
  # See: https://github.com/prestosql/presto/issues/391 
  size = 1

  project    = var.project
  region     = var.region
  zone       = var.zone
  network    = var.network
  subnetwork = var.subnetwork

  compute_image = var.coordinator_image
  machine_type  = var.coordinator_type
  disk_type     = var.coordinator_disk_type

  startup_script = (var.coordinator_startup_script != "" ? var.coordinator_startup_script : data.template_file.coordinator-startup-script.rendered)

  service_account_scopes = var.service_account_scopes
  service_port           = var.http_port
  service_port_name      = "http"
  http_health_check      = false
  target_pools           = [google_compute_target_pool.presto.self_link]
  target_tags = [
    "allow-presto-${var.environment_name}-coordinator",
    "allow-presto-${var.environment_name}"
  ]

  wait_for_instances = true
  update_policy = {
    type                    = "PROACTIVE"
    minimal_action          = "REPLACE"
    max_surge_fixed         = 1
    max_surge_percent       = null
    max_unavailable_fixed   = 1
    max_unavailable_percent = null
    min_ready_sec           = null
  }
}

data "template_file" "worker_config" {
  template = file(format("%s/templates/worker.config.tpl", path.module))

  vars = {
    COORDINATOR = "http://${google_compute_forwarding_rule.presto.ip_address}:${var.http_port}"
    PORT        = var.http_port
  }
}

data "template_file" "worker-startup-script" {
  template = file(format("%s/templates/startup.sh.tpl", path.module))

  vars = {
    ENV_NAME      = var.environment_name
    PRESTO_CONFIG = (var.worker_config != "" ? var.worker_config : data.template_file.worker_config.rendered)
  }
}

module "worker_group" {
  # source  = "GoogleCloudPlatform/managed-instance-group/google"
  # version = "1.1.15"
  # Using Fork as original is incompatible with the Google >= 2.0 provider
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  source = "git::https://github.com/rchukh/terraform-google-managed-instance-group.git?ref=terraform_0.12"

  name = (var.worker_group_name != "" ? var.worker_group_name : "presto-${var.environment_name}-workers")

  size = var.worker_group_size

  project    = var.project
  region     = var.region
  zone       = var.zone
  network    = var.network
  subnetwork = var.subnetwork

  compute_image = var.worker_image
  machine_type  = var.worker_type
  disk_type     = var.worker_disk_type

  startup_script = (var.worker_startup_script != "" ? var.worker_startup_script : data.template_file.worker-startup-script.rendered)

  service_account_scopes = var.service_account_scopes
  service_port           = var.http_port
  service_port_name      = "http"
  http_health_check      = false
  target_pools           = []
  target_tags            = ["allow-presto-${var.environment_name}"]

  wait_for_instances = true
  update_policy = {
    type                    = "PROACTIVE"
    minimal_action          = "REPLACE"
    max_surge_fixed         = 1
    max_surge_percent       = null
    max_unavailable_fixed   = 1
    max_unavailable_percent = null
    min_ready_sec           = null
  }
}
