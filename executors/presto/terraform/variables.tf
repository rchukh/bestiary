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

variable "environment_name" {
  description = "PrestoSQL Environment Name (used in WEB UI)"
}

variable "http_port" {
  description = "Presto HTTP Port. Presto uses HTTP for all communication, internal and external."
  default     = "8080"
}

variable "coordinator_group_name" {
  description = "Coordinator Instance Group Name"
  default     = "prestosql-coordinator-group"
}

variable "coordinator_group_lb_name" {
  description = "Coordinator Instance Group Load Balancer Name"
  default     = "prestosql-coordinator-lb"
}

variable "coordinator_image" {
  description = "PrestoSQL Image to use for coordinator"
  default     = "centos-cloud/centos-7"
}

variable "coordinator_type" {
  description = "Coordinator Instance type"
  default     = "f1-micro"
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

variable "worker_group_name" {
  description = "Worker Instance Group Name"
  default     = "prestosql-worker-group"
}

variable "worker_group_size" {
  description = "Amount of workers."
  default     = "1"
}

variable "worker_image" {
  description = "PrestoSQL Image to use for worker"
  default     = "centos-cloud/centos-7"
}

variable "worker_type" {
  description = "Worker Instance type"
  default     = "f1-micro"
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
