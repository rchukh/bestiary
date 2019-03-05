provider "google" {
  # TODO: Update to 2.X, once the following are merged:
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  version = "~> 1.20"

  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_compute_network" "prestosql" {
  name                    = "bestiary-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "prestosql" {
  name          = "bestiary-default"
  network       = "${google_compute_network.prestosql.self_link}"
  ip_cidr_range = "10.0.0.0/16"
}

module "prestosql" {
  source = "../../"

  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"

  network    = "${google_compute_network.prestosql.self_link}"
  subnetwork = "${google_compute_subnetwork.prestosql.prestosql.self_link}"

  environment_name          = "single_node"
  coordinator_group_name    = "single-coordinator"
  coordinator_group_lb_name = "single-coordinator-lb"
  worker_group_name         = "single-worker"
  worker_group_size         = 1
}
