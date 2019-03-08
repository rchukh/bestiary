output "coordinator_lb_ip" {
  value = "${google_compute_forwarding_rule.prestosql.ip_address}"
}
