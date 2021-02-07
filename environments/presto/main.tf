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
  postfix              = random_id.name.hex
  hms_cloud_sql_name   = format("bestiary-hms-%s", random_id.name.hex)
  hms_config_bucket    = format("bestiary_hms_config_%s", random_id.name.hex)
  hms_warehouse_bucket = format("bestiary_hms_warehouse_%s", random_id.name.hex)
  trino_config_bucket  = format("bestiary_trino_config_%s", random_id.name.hex)
}

##
# General
##
resource "google_project_service" "storage-component" {
  provider                   = "google-beta"
  service                    = "storage-component.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_compute_network" "bestiary" {
  provider                = "google-beta"
  name                    = "bestiary-vpc-${local.postfix}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "bestiary" {
  provider      = "google-beta"
  name          = "bestiary-${local.postfix}"
  network       = google_compute_network.bestiary.self_link
  region        = var.region
  ip_cidr_range = "10.0.0.0/16"
}


##
# Hive Metastore
##
resource "google_project_service" "sqladmin" {
  provider                   = "google-beta"
  service                    = "sqladmin.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_sql_database_instance" "hms" {
  provider         = "google-beta"
  name             = local.hms_cloud_sql_name
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

resource "google_sql_user" "hms" {
  provider = "google-beta"
  name     = "hms"
  instance = google_sql_database_instance.hms.name
  host     = "%"
  password = "hms"
}

resource "google_sql_database" "hms" {
  provider = "google-beta"
  name     = "hms"
  instance = google_sql_database_instance.hms.name
}

resource "google_storage_bucket" "hms_config" {
  provider = "google-beta"
  project  = var.project
  name     = local.hms_config_bucket
  location = "europe-west1"
}

resource "google_storage_bucket" "hms_warehouse" {
  provider = "google-beta"
  project  = var.project
  name     = local.hms_warehouse_bucket
  location = "EU"
}

module "hms" {
  source = "../../keepers/hive-metastore/terraform/"

  instance_image = "bestiary-hive-metastore-1564999356"

  project = var.project
  region  = var.region
  zone    = var.zone

  network          = google_compute_network.bestiary.self_link
  subnetwork       = google_compute_subnetwork.bestiary.self_link
  subnetwork_range = google_compute_subnetwork.bestiary.ip_cidr_range

  cloudsql_instance_connection_enabled = "1"
  cloudsql_instance_connection_name    = google_sql_database_instance.hms.connection_name
  database_host                        = "localhost"
  database_port                        = "3306"
  database_name                        = google_sql_database.hms.name
  database_user                        = google_sql_user.hms.name
  database_password                    = google_sql_user.hms.password

  gcs_bucket    = google_storage_bucket.hms_config.name
  warehouse_dir = "gs://${google_storage_bucket.hms_warehouse.name}/warehouse"

  # NOTE: Environment name is used in GCP resources name (e.g. cannot contain some symbols _)
  environment_name = var.environment_name

  # Do not expose HMS externally
  lb_schema = "INTERNAL"
}

##
# trino
##
resource "google_storage_bucket" "trino_config" {
  provider = "google-beta"
  project  = var.project
  name     = local.trino_config_bucket
  location = "europe-west1"
}

data "template_file" "hive_catalog" {
  template = file(format("%s/templates/hive.properties", path.module))

  vars = {
    HMS_HOST = module.hms.metastore_lb_ip
    HMS_PORT = module.hms.metastore_lb_port
  }
}

module "trino" {
  source = "..\/..\/executors\/trino/terraform/"

  coordinator_image = "bestiary-trino-1564999725"
  worker_image      = "bestiary-trino-1564999725"

  project = var.project
  region  = var.region
  zone    = var.zone

  network          = google_compute_network.bestiary.self_link
  subnetwork       = google_compute_subnetwork.bestiary.self_link
  subnetwork_range = google_compute_subnetwork.bestiary.ip_cidr_range

  # NOTE: Environment name is used in GCP resources name (e.g. cannot contain some symbols _)
  environment_name  = var.environment_name
  worker_group_size = 1

  gcs_bucket = google_storage_bucket.trino_config.name
  catalogs = [
    {
      file_name = "hive.properties"
      content   = data.template_file.hive_catalog.rendered
    },
    {
      file_name = "tpch.properties"
      content   = "connector.name=tpch"
    },
    {
      file_name = "tpcds.properties"
      content   = "connector.name=tpcds"
    }
  ]
}
