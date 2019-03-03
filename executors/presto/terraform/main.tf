# TODO: Parameterize everything and clean up module
provider "google" {
  # TODO: Update to 2.X, once the following are merged:
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  version = "~> 1.20"

  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_compute_network" "bestiary_vpc" {
  name                    = "bestiary-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "bestiary_default" {
  name          = "bestiary-default"
  network       = "${google_compute_network.bestiary_vpc.self_link}"
  ip_cidr_range = "10.0.0.0/16"
}

module "coordinator-lb" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "1.0.3"
  region       = "${var.region}"
  name         = "${var.coordinator_group_lb_name}"
  network      = "${google_compute_network.bestiary_vpc.self_link}"
  service_port = "${module.coordinator_group.service_port}"
  target_tags  = ["${module.coordinator_group.target_tags}"]
}

module "coordinator_group" {
  source  = "GoogleCloudPlatform/managed-instance-group/google"
  version = "1.1.15"
  region  = "${var.region}"
  zone    = "${var.zone}"
  name    = "${var.coordinator_group_name}"

  # Coordinator Pool is fixed to 1 (PrestoSQL specifics) 
  size              = 1

  machine_type  = "${var.coordinator_type}"
  network       = "${google_compute_network.bestiary_vpc.self_link}"
  subnetwork    = "${google_compute_subnetwork.bestiary_default.self_link}"
  
  service_port      = 8080
  service_port_name = "http"
  http_health_check = false
  target_pools      = ["${module.coordinator-lb.target_pool}"]
  target_tags       = ["allow-service1"]
  startup_script    = ""
}
