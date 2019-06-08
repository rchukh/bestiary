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

variable "subnetwork_range" {
  description = "Presto Cluster Subnetwork Range (to allow coordinator<->worker communications)"
}

variable "environment_name" {
  description = "Presto Environment Name (used in WEB UI)"
}

variable "http_port" {
  description = "Presto HTTP Port. Presto uses HTTP for all communication, internal and external."
  default     = "8080"
}

variable "coordinator_group_name" {
  description = "Coordinator Instance Group Name"
  default     = ""
}

variable "coordinator_group_lb_name" {
  description = "Coordinator Instance Group Load Balancer Name"
  default     = ""
}

variable "coordinator_group_lb_schema" {
  description = "Coordinator Instance Group Load Balancing schema (EXTERNAL, INTERNAL)"
  default     = "EXTERNAL"
}

variable "coordinator_image" {
  description = "Presto Image to use for coordinator"
  default     = "bestiary-prestosql-1559998233"
}

variable "coordinator_type" {
  description = "Coordinator Instance type"
  default     = "n1-standard-4"
}

variable "coordinator_disk_type" {
  description = "Coordinator Disk type"

  # local-ssd not available on boot node
  # pd-ssd a bit pricey
  default = "pd-standard"
}

variable "coordinator_config" {
  description = "Coordinator config.properties override"
  default     = ""
}

variable "coordinator_startup_script" {
  description = "Coordinator startup script override"
  default     = ""
}

variable "coordinator_update_policy" {
  description = "The upgrade policy to apply when the instance template changes."
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

variable "worker_group_name" {
  description = "Worker Instance Group Name"
  default     = ""
}

variable "worker_group_size" {
  description = "Amount of workers."
  default     = "1"
}

variable "worker_image" {
  description = "Presto Image to use for worker"
  default     = "bestiary-prestosql-1559998233"
}

variable "worker_type" {
  description = "Worker Instance type"
  default     = "n1-standard-4"
}

variable "worker_disk_type" {
  description = "Worker Disk type"

  # local-ssd not available on boot node
  # pd-ssd a bit pricey (not needed until "spill to disk" is non-experimental)
  default = "pd-standard"
}

variable "worker_config" {
  description = "Worker config.properties override"
  default     = ""
}

variable "worker_startup_script" {
  description = "Worker startup script override"
  default     = ""
}

variable "worker_update_policy" {
  description = "The upgrade policy to apply when the instance template changes."
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
    "https://www.googleapis.com/auth/devstorage.full_control",
  ]
}