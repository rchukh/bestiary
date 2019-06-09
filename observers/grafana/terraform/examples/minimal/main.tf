provider "google-beta" {
  version = "~> 2.8.0"

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "grafana" {
  provider                = "google-beta"
  name                    = "bestiary-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "grafana" {
  provider      = "google-beta"
  name          = "bestiary-default"
  network       = google_compute_network.grafana.self_link
  region        = var.region
  ip_cidr_range = "10.0.0.0/16"
}

resource "google_compute_firewall" "grafana" {
  name = "grafana"

  project = var.project
  network = google_compute_network.grafana.self_link

  allow {
    protocol = "tcp"
    ports    = ["3000", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-grafana"]
}

module "grafana" {
  source = "../../"

  project = var.project
  region  = var.region
  zone    = var.zone

  network    = google_compute_network.grafana.self_link
  subnetwork = google_compute_subnetwork.grafana.self_link

  instance_tags = ["allow-grafana"]
}
