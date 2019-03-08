# TODO: Parameterize everything
terraform {
  required_version = "~> 0.11.11"
}

provider "google" {
  # TODO: Update to 2.X, once the following are merged:
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  version = "~> 1.20"

  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_compute_http_health_check" "prestosql" {
  name = "${var.coordinator_group_lb_name != ""
                   ? var.coordinator_group_lb_name
                   : "${var.environment_name}-lb"}"

  project      = "${var.project}"
  port         = "${var.http_port}"
  request_path = "/v1/status"
}

resource "google_compute_target_pool" "prestosql" {
  name = "${var.environment_name}-pool"

  project          = "${var.project}"
  region           = "${var.region}"
  session_affinity = "NONE"
  health_checks    = ["${google_compute_http_health_check.prestosql.name}"]
}

resource "google_compute_forwarding_rule" "prestosql" {
  name = "${var.environment_name}-fr"

  project               = "${var.project}"
  target                = "${google_compute_target_pool.prestosql.self_link}"
  load_balancing_scheme = "${var.coordinator_group_lb_schema}"
  port_range            = "${var.http_port}"
}

# TODO: Set source_ranges to internal network in case of Internal LB 
resource "google_compute_firewall" "prestosql-lb-fw" {
  name = "presto-${var.environment_name}-fr"

  project = "${var.project}"
  network = "${var.network}"

  allow {
    protocol = "tcp"
    ports    = ["${module.coordinator_group.service_port}"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-presto-${var.environment_name}-coordinator"]
}

# Allow communications between coordinator and workers
resource "google_compute_firewall" "prestosql" {
  project = "${var.project}"
  network = "${var.network}"

  name = "${var.worker_group_name != ""
          ? var.worker_group_name
          : "${var.environment_name}-communications"}"

  allow {
    protocol = "tcp"
    ports    = ["${var.http_port}"]
  }

  source_ranges = ["${var.subnetwork_range}"]
  target_tags   = ["allow-presto-${var.environment_name}"]
}

data "template_file" "coordinator_config" {
  template = "${file("${format("%s/templates/coordinator.config.tpl", path.module)}")}"

  vars {
    # NOTE: Coordinator does not need to go through LB to its own location.
    PRESTOSQL_COORDINATOR = "http://localhost:${var.http_port}"
    PRESTOSQL_PORT        = "${var.http_port}"
  }
}

data "template_file" "coordinator-startup-script" {
  template = "${file("${format("%s/templates/startup.sh.tpl", path.module)}")}"

  vars {
    PRESTOSQL_ENV_NAME = "${var.environment_name}"

    PRESTOSQL_CONFIG = "${var.coordinator_config != ""
      ? var.coordinator_config
      : data.template_file.coordinator_config.rendered}"
  }
}

module "coordinator_group" {
  source  = "GoogleCloudPlatform/managed-instance-group/google"
  version = "1.1.15"

  name = "${var.coordinator_group_name != ""
          ? var.coordinator_group_name
          : "${var.environment_name}-coordinators"}"

  # Coordinator Pool is fixed to 1 (PrestoSQL specifics) 
  # See: https://github.com/prestosql/presto/issues/391 
  size = 1

  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${var.network}"
  subnetwork = "${var.subnetwork}"

  compute_image = "${var.coordinator_image}"
  machine_type  = "${var.coordinator_type}"
  disk_type     = "${var.coordinator_disk_type}"

  startup_script = "${var.coordinator_startup_script != "" 
                    ? var.coordinator_startup_script 
                    : data.template_file.coordinator-startup-script.rendered}"

  service_port      = "${var.http_port}"
  service_port_name = "http"
  http_health_check = false
  target_pools      = ["${google_compute_target_pool.prestosql.self_link}"]
  target_tags       = ["allow-presto-${var.environment_name}-coordinator", "allow-presto-${var.environment_name}"]

  wait_for_instances = true
}

data "template_file" "worker_config" {
  template = "${file("${format("%s/templates/worker.config.tpl", path.module)}")}"

  vars {
    PRESTOSQL_COORDINATOR = "http://${google_compute_forwarding_rule.prestosql.ip_address}:${var.http_port}"
    PRESTOSQL_PORT        = "${var.http_port}"
  }
}

data "template_file" "worker-startup-script" {
  template = "${file("${format("%s/templates/startup.sh.tpl", path.module)}")}"

  vars {
    PRESTOSQL_ENV_NAME = "${var.environment_name}"

    PRESTOSQL_CONFIG = "${var.worker_config != ""
      ? var.worker_config
      : data.template_file.worker_config.rendered}"
  }
}

module "worker_group" {
  source  = "GoogleCloudPlatform/managed-instance-group/google"
  version = "1.1.15"

  name = "${var.worker_group_name != ""
          ? var.worker_group_name
          : "${var.environment_name}-workers"}"

  size = "${var.worker_group_size}"

  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${var.network}"
  subnetwork = "${var.subnetwork}"

  compute_image = "${var.worker_image}"
  machine_type  = "${var.worker_type}"
  disk_type     = "${var.worker_disk_type}"

  startup_script = "${var.worker_startup_script != "" 
                   ? var.worker_startup_script 
                   : data.template_file.worker-startup-script.rendered}"

  # TODO: Wait for 0.12 nulls?
  # https://www.hashicorp.com/blog/terraform-0-12-conditional-operator-improvements
  # service_account_scopes = "${var.service_account_scopes}"

  service_port       = "${var.http_port}"
  service_port_name  = "http"
  http_health_check  = false
  target_pools       = []
  target_tags        = ["allow-presto-${var.environment_name}"]
  wait_for_instances = true
}
