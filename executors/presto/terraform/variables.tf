variable "project" {
  description = "The GCP project to use."
  default     = "bestiary-218008"
}

variable "region" {
  description = "The GCP region to use."
  default     = "europe-west1"
}

variable "network_name" {
  description = "The GCP Network Name"
  default     = "bestiary-vpc"
}

variable "subnetwork_name" {
  description = "The GCP Subnetwork Name"
  default     = "bestiary-default"
}

variable "subnetwork_ip_cidr_range" {
  description = "The GCP Subnetwork CIDR"
  default     = "10.0.0.0/16"
}

variable "zone" {
  description = "The GCP region zone to use."
  default     = "europe-west1-d"
}

variable "environment_name" {
  description = "PrestoSQL Environment Name (used in WEB UI)"
  default     = "bestiary"
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

variable "coordinator_startup_script" {
  description = "Coordinator startup script override"
  default     = ""
}

variable "workers" {
  description = "Amount of workers."
  default     = "1"
}

variable "worker_group_name" {
  description = "Worker Instance Group Name"
  default     = "prestosql-worker-group"
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

variable "worker_startup_script" {
  description = "Worker startup script override"
  default     = ""
}
