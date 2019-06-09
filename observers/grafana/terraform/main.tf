# TODO: https://www.terraform.io/docs/providers/grafana/index.html
terraform {
  required_version = "~> 0.12"
}

data "template_file" "startup-script" {
  template = file(format("%s/templates/startup.sh.tpl", path.module))
  vars = {
    DB_TYPE            = var.database_type
    DB_HOST            = var.database_host
    DB_NAME            = var.database_name
    DB_USER            = var.database_user
    DB_PASS            = var.database_pass
    DB_SSL_MODE        = var.database_ssl_mode
    GRAFANA_ADMIN      = var.default_admin_user
    GRAFANA_ADMIN_PASS = var.default_admin_pass
  }
}

resource "google_compute_instance" "grafana" {
  name                      = var.instance_name
  machine_type              = var.machine_type
  project                   = var.project
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.machine_image
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      // Ephemeral IP
    }
  }
  tags = var.instance_tags

  metadata = {
    startup-script = data.template_file.startup-script.rendered
  }
  # metadata_startup_script = data.template_file.startup-script.rendered

  service_account {
    scopes = var.service_account_scopes
  }
}