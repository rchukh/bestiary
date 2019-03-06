# TODO: Parameterize everything
terraform {
  required_version = "~> 0.11.11"
}

provider "google" {
  # TODO: Update to 2.X, once the following are merged:
  # - https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/pull/39
  version = "~> 1.20"

  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

data "template_file" "coordinator_config" {
  template = "${file("${format("%s/templates/coordinator.config.tpl", path.module)}")}"

  vars {
    # NOTE: Coordinator does not need to go through LB to its own location.
    PRESTOSQL_COORDINATOR = "http://localhost:${var.http_port}"
    PRESTOSQL_PORT        = "${var.http_port}"
  }
}

data "template_file" "coordinator-startup-script" {
  template = "${file("${format("%s/templates/startup.sh.tpl", path.module)}")}"

  vars {
    PRESTOSQL_ENV_NAME = "${var.environment_name}"

    PRESTOSQL_CONFIG = "${var.coordinator_config != ""
      ? var.coordinator_config
      : data.template_file.coordinator_config.rendered}"
  }
}

module "coordinator_lb" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "1.0.3"
  region       = "${var.region}"
  name         = "${var.coordinator_group_lb_name}"
  network      = "${var.network}"
  service_port = "${module.coordinator_group.service_port}"
  target_tags  = ["${module.coordinator_group.target_tags}"]
}

# NOTE: Just for tmp reference. There is no need for global HTTP LB.
# module "coordinator_lb" {
#   source            = "GoogleCloudPlatform/lb-http/google"
#   version           = "1.0.10"
#   region            = "${var.region}"
#   name              = "${var.coordinator_group_lb_name}"
#   firewall_networks = ["${var.network}"]
#   backend_protocol = "HTTP"
#   http_forward     = true
#   ssl              = false
#   target_tags = ["${module.coordinator_group.target_tags}"]
#   backends = {
#     "0" = [
#       {
#         group = "${module.coordinator_group.instance_group}"
#       },
#     ]
#   }
#   backend_params = [
#     // health check path, port name, port number, timeout seconds.
#     "/,http,${module.coordinator_group.service_port},30",
#   ]
# }

module "coordinator_group" {
  source  = "GoogleCloudPlatform/managed-instance-group/google"
  version = "1.1.15"

  name = "${var.coordinator_group_name}"

  # Coordinator Pool is fixed to 1 (PrestoSQL specifics) 
  # See: https://github.com/prestosql/presto/issues/391 
  size = 1

  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${var.network}"
  subnetwork = "${var.subnetwork}"

  compute_image = "${var.coordinator_image}"
  machine_type  = "${var.coordinator_type}"
  disk_type     = "${var.coordinator_disk_type}"

  startup_script = "${var.coordinator_startup_script != "" 
  ? var.coordinator_startup_script 
  : data.template_file.coordinator-startup-script.rendered}"

  service_port      = "${var.http_port}"
  service_port_name = "http"
  http_health_check = false
  target_pools      = ["${module.coordinator_lb.target_pool}"]
  target_tags       = ["allow-prestosql-coordinator"]

  wait_for_instances = true
}

data "template_file" "worker_config" {
  template = "${file("${format("%s/templates/coordinator.config.tpl", path.module)}")}"

  vars {
    PRESTOSQL_COORDINATOR = "http://${module.coordinator_lb.external_ip}:${var.http_port}"
    PRESTOSQL_PORT        = "${var.http_port}"
  }
}

data "template_file" "worker-startup-script" {
  template = "${file("${format("%s/templates/startup.sh.tpl", path.module)}")}"

  vars {
    PRESTOSQL_ENV_NAME = "${var.environment_name}"

    PRESTOSQL_CONFIG = "${var.worker_config != ""
      ? var.worker_config
      : data.template_file.worker_config.rendered}"
  }
}

module "worker_group" {
  source  = "GoogleCloudPlatform/managed-instance-group/google"
  version = "1.1.15"

  name = "${var.worker_group_name}"
  size = "${var.worker_group_size}"

  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${var.network}"
  subnetwork = "${var.subnetwork}"

  compute_image = "${var.worker_image}"
  machine_type  = "${var.worker_type}"
  disk_type     = "${var.worker_disk_type}"

  startup_script = "${var.worker_startup_script != "" 
  ? var.worker_startup_script 
  : data.template_file.worker-startup-script.rendered}"

  # TODO: Wait for 0.12 nulls?
  # https://www.hashicorp.com/blog/terraform-0-12-conditional-operator-improvements
  # service_account_scopes = "${var.service_account_scopes}"

  service_port       = "${var.http_port}"
  service_port_name  = "http"
  http_health_check  = false
  target_pools       = []
  target_tags        = ["allow-prestosql-worker"]
  wait_for_instances = true
}
