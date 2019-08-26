output "metastore_lb_ip" {
  value = google_compute_forwarding_rule.hms.ip_address
}

output "metastore_lb_port" {
  value = var.http_port
}
