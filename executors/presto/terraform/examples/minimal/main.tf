provider "google-beta" {
  version = "~> 2.12.0"

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "presto" {
  provider                = "google-beta"
  name                    = "bestiary-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "presto" {
  provider      = "google-beta"
  name          = "bestiary-default"
  network       = google_compute_network.presto.self_link
  region        = var.region
  ip_cidr_range = "10.0.0.0/16"
}

resource "google_storage_bucket" "presto_config" {
  project  = var.project
  name     = "bestiary_presto_config"
  location = "europe-west1"
}

module "presto" {
  source = "../../"

  project = var.project
  region  = var.region
  zone    = var.zone

  network          = google_compute_network.presto.self_link
  subnetwork       = google_compute_subnetwork.presto.self_link
  subnetwork_range = google_compute_subnetwork.presto.ip_cidr_range

  # NOTE: Environment name is used in GCP resources name (e.g. cannot contain some symbols _)
  environment_name  = "singlenode"
  worker_group_size = 1

  gcs_bucket = google_storage_bucket.presto_config.name
  catalogs = [
    {
      file_name = "tpch.properties"
      content   = "connector.name=tpch"
    }
  ]
}
