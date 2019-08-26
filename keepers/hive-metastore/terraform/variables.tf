variable "project" {
  description = "The GCP project to use"
}

variable "region" {
  description = "The GCP region to use"
  default     = "europe-west1"
}

variable "zone" {
  description = "The GCP region zone to use"
  default     = "europe-west1-d"
}

variable "network" {
  description = "The GCP Network"
}

variable "subnetwork" {
  description = "The GCP Subnetwork"
}

variable "subnetwork_range" {
  description = "Subnetwork Range"
}

variable "environment_name" {
  description = "Environment Name"
}

variable "gcs_bucket" {
  description = "Bucket name to store configurations."
}

variable "http_port" {
  description = "Hive Metastore HTTP Port"
  default     = "9083"
}

variable "jmx_port" {
  description = "JMX Exporter Port"
  type        = "string"
  default     = "8081"
}

variable "subnet_ports" {
  description = "Additional Ports to expose in the subnet."
  type        = "list"
  default = [
    # Node Exporter
    "9100"
  ]
}

variable "additional_hosts" {
  description = "List of hosts to add to /etc/hosts"
  type        = "list"
  default     = []
}

variable "instance_group_name" {
  description = "Instance Group Name"
  default     = ""
}

variable "instance_group_lb_name" {
  description = "Instance Group Load Balancer Name"
  default     = ""
}

variable "lb_schema" {
  description = "Instance Group Load Balancing schema (EXTERNAL, INTERNAL)"
  default     = "EXTERNAL"
}

variable "instance_group_size" {
  description = "Amount of nodes in the instance group"
  type        = number
  default     = "1"
}

variable "cloudsql_instance_connection_enabled" {
  description = "Use preinstalled cloudsql binary."
  default     = "0"
}

variable "cloudsql_instance_connection_name" {
  description = "CloudSQL connection string (if used)."
  default     = ""
}

variable "database_host" {
  description = "Database (MySQL only) host for Hive Metastore."
}

variable "database_port" {
  description = "Database (MySQL only) port for Hive Metastore."
}

variable "database_name" {
  description = "Database name for Hive Metastore."
}

variable "database_user" {
  description = "Database user name for Hive Metastore."
}

variable "database_password" {
  description = "Database user password for Hive Metastore."
}

variable "warehouse_dir" {
  description = "Hive Metastore default warehouse dir."
}

variable "instance_image" {
  description = "Hive Metastore Image to use"
  default     = "bestiary-hive-metastore-1564659533"
}

variable "instance_type" {
  description = "Instance type"
  default     = "n1-standard-2"
}

variable "instance_disk_type" {
  description = "Disk type"

  # local-ssd not available on boot node
  # pd-ssd a bit pricey
  default = "pd-standard"
}

variable "custom_bootstrap" {
  description = "Startup script override"
  default     = ""
}

variable "zonal" {
  description = "Instance group type. Zonal if true, Regional if false."
  default     = true
}

variable "distribution_policy_zones" {
  description = "The distribution policy for this managed instance group when zonal=false. Default is all zones in given region."
  type        = "list"
  default     = []
}

variable "instance_group_update_policy" {
  description = "The upgrade policy to apply when the instance template changes"
  type = object({
    type                    = string
    minimal_action          = string
    max_surge_fixed         = number
    max_surge_percent       = number
    max_unavailable_fixed   = number
    max_unavailable_percent = number
    min_ready_sec           = number
  })
  default = {
    type                    = "PROACTIVE"
    minimal_action          = "REPLACE"
    max_surge_fixed         = 1
    max_surge_percent       = null
    max_unavailable_fixed   = 1
    max_unavailable_percent = null
    min_ready_sec           = null
  }
}

variable "service_account_scopes" {
  description = "List of scopes for the instance template service account"
  type        = "list"

  default = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/sqlservice.admin",
    "https://www.googleapis.com/auth/devstorage.full_control",
  ]
}
