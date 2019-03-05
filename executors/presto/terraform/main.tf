# TODO: Parameterize everything
# TODO: Clean up module
# TODO: Add Terragrunt support
# terraform {
#   # Will be filled by Terragrunt
#   backend "gcs" {}
# }
provider "google" {
  # TODO: Update to 2.X, once the following are merged:
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  version = "~> 1.20"

  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_compute_network" "prestosql" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "prestosql" {
  name          = "${var.subnetwork_name}"
  network       = "${google_compute_network.prestosql.self_link}"
  ip_cidr_range = "${var.subnetwork_ip_cidr_range}"
}

data "template_file" "coordinator-startup-script" {
  template = "${file("${format("%s/templates/startup.sh.tpl", path.module)}")}"

  vars {
    PRESTOSQL_ENV_NAME = "${var.environment_name}"

    # NOTE: Coordinator does not need to go through LB to its own location.
    PRESTOSQL_COORDINATOR = "localhost:8080"
  }
}

module "coordinator_lb" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "1.0.3"
  region       = "${var.region}"
  name         = "${var.coordinator_group_lb_name}"
  network      = "${google_compute_network.prestosql.self_link}"
  service_port = "${module.coordinator_group.service_port}"
  target_tags  = ["${module.coordinator_group.target_tags}"]
}

module "coordinator_group" {
  source  = "GoogleCloudPlatform/managed-instance-group/google"
  version = "1.1.15"

  name = "${var.coordinator_group_name}"

  # Coordinator Pool is fixed to 1 (PrestoSQL specifics) 
  size = 1

  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${google_compute_network.prestosql.self_link}"
  subnetwork = "${google_compute_subnetwork.prestosql.self_link}"

  compute_image = "${var.coordinator_image}"
  machine_type  = "${var.coordinator_type}"
  disk_type     = "${var.coordinator_disk_type}"

  startup_script = "${var.coordinator_startup_script != "" 
  ? var.coordinator_startup_script 
  : data.template_file.coordinator-startup-script.rendered}"

  service_port      = 8080
  service_port_name = "http"
  http_health_check = false
  target_pools      = ["${module.coordinator_lb.target_pool}"]
  target_tags       = ["allow-prestosql-coordinator"]

  wait_for_instances = true
}

data "template_file" "worker-startup-script" {
  template = "${file("${format("%s/templates/startup.sh.tpl", path.module)}")}"

  vars {
    PRESTOSQL_ENV_NAME    = "${var.environment_name}"
    PRESTOSQL_COORDINATOR = "${module.coordinator_lb.external_ip}"
  }
}

module "worker_group" {
  source  = "GoogleCloudPlatform/managed-instance-group/google"
  version = "1.1.15"
  
  name    = "${var.worker_group_name}"
  size    = "${var.workers}"

  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${google_compute_network.prestosql.self_link}"
  subnetwork = "${google_compute_subnetwork.prestosql.self_link}"

  compute_image = "${var.worker_image}"
  machine_type  = "${var.worker_type}"
  disk_type     = "${var.worker_disk_type}"

  startup_script = "${var.worker_startup_script != "" 
  ? var.worker_startup_script 
  : data.template_file.worker-startup-script.rendered}"

  # TODO: Wait for 0.12 nulls?
  # https://www.hashicorp.com/blog/terraform-0-12-conditional-operator-improvements
  # service_account_scopes = "${var.service_account_scopes}"

  service_port      = 8080
  service_port_name = "http"
  http_health_check = false
  target_pools      = []
  target_tags       = ["allow-prestosql-worker"]
  wait_for_instances = true
}
