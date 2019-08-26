terraform {
  required_version = ">= 0.12"
}

provider "google-beta" {
  version = "~> 2.12.0"

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "random_id" "name" {
  byte_length = 2
}

locals {
  instance_name = format("hms-%s", random_id.name.hex)
}

resource "google_project_service" "storage-component" {
  provider                   = "google-beta"
  service                    = "storage-component.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "sqladmin" {
  provider                   = "google-beta"
  service                    = "sqladmin.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_compute_network" "hms" {
  provider                = "google-beta"
  name                    = "bestiary-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "hms" {
  provider      = "google-beta"
  name          = "bestiary-default"
  network       = google_compute_network.hms.self_link
  region        = var.region
  ip_cidr_range = "10.0.0.0/16"
}

resource "google_sql_database_instance" "hms" {
  provider         = "google-beta"
  name             = local.instance_name
  database_version = "MYSQL_5_7"

  settings {
    tier      = "db-f1-micro"
    disk_type = "PD_HDD"

    backup_configuration {
      binary_log_enabled = "false"
      enabled            = "false"
    }

    # Potential Maintenance only at Sunday 3 AM UTC time
    maintenance_window {
      day          = "7"
      hour         = "3"
      update_track = "stable"
    }
  }
}

resource "google_sql_user" "metastore" {
  provider = "google-beta"
  name     = "hms"
  instance = google_sql_database_instance.hms.name
  host     = "%"
  password = "hms"
}

resource "google_sql_database" "metastore" {
  provider = "google-beta"
  name     = "hms"
  instance = google_sql_database_instance.hms.name
}

resource "google_storage_bucket" "warehouse" {
  provider = "google-beta"
  project  = var.project
  name     = "bestiary_hive_metastore_config_test"
  location = "EU"
}

resource "google_storage_bucket" "config" {
  provider = "google-beta"
  project  = var.project
  name     = "bestiary_hive_metastore_config"
  location = "europe-west1"
}


module "hms" {
  source = "../../"

  project = var.project
  region  = var.region
  zone    = var.zone

  network          = google_compute_network.hms.self_link
  subnetwork       = google_compute_subnetwork.hms.self_link
  subnetwork_range = google_compute_subnetwork.hms.ip_cidr_range

  cloudsql_instance_connection_enabled = "1"
  cloudsql_instance_connection_name    = google_sql_database_instance.hms.connection_name
  database_host                        = "localhost"
  database_port                        = "3306"
  database_name                        = google_sql_database.metastore.name
  database_user                        = google_sql_user.metastore.name
  database_password                    = google_sql_user.metastore.password

  gcs_bucket    = google_storage_bucket.config.name
  warehouse_dir = "gs://${google_storage_bucket.warehouse.name}/hive_metastore_example"

  # NOTE: Environment name is used in GCP resources name (e.g. cannot contain some symbols _)
  environment_name = "lb-cloudsql"
}
