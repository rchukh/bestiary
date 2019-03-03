variable "project" {
  description = "The GCP project to use."
  default     = "bestiary-218008"
}

variable "region" {
  description = "The GCP region to use."
  default     = "europe-west1"
}

variable "zone" {
  description = "The GCP region zone to use."
  default     = "europe-west1-d"
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

variable "workers" {
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
