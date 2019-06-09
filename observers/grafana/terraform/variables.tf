variable "project" {
  description = "The GCP project to use."
}

variable "region" {
  description = "The GCP region to use."
  default     = "europe-west1"
}

variable "zone" {
  description = "The GCP region zone to use."
  default     = "europe-west1-d"
}

variable "network" {
  description = "The GCP Network"
}

variable "subnetwork" {
  description = "The GCP Subnetwork"
}

variable "instance_name" {
  default = "grafana"
}

variable "instance_tags" {
  default = []
}

variable "machine_type" {
  default = "f1-micro"
}

variable "machine_image" {
  description = "Grafana Image"
  default     = "bestiary-grafana-1560074078"
}

variable "service_account_scopes" {
  description = "List of scopes for the instance service account"
  type        = "list"

  default = [
    # Compute Instance Defaults
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
    # Access to the list of compute instances
    "https://www.googleapis.com/auth/compute.readonly"
  ]
}

variable "database_type" {
  default = "sqlite3"
}

variable "database_host" {
  default = ""
}

variable "database_name" {
  default = "grafana"
}

variable "database_user" {
  default = ""
}

variable "database_pass" {
  default = ""
}

variable "database_ssl_mode" {
  description = "SSL Mode. For Postgres, use either disable, require or verify-full. For MySQL, use either true, false, or skip-verify."
  default     = ""
}

variable "default_admin_user" {
  description = "The name of the default Grafana admin user"
  default     = "admin"
}

variable "default_admin_pass" {
  description = "The password of the default Grafana admin. Set once on first-run."
  default     = "admin"
}