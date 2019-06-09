output "grafana_endpoint" {
  value = format("%s:%s", google_compute_instance.grafana.network_interface[0].network_ip, ":3000")
}