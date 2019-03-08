output "coordinator_lb_ip" {
  value = "${google_compute_forwarding_rule.presto.ip_address}"
}
