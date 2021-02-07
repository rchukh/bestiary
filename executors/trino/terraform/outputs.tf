output "coordinator_lb_ip" {
  value = google_compute_forwarding_rule.trino.ip_address
}
