output "coordinator_lb_ip" {
  value = "${module.coordinator_lb.external_ip}"
}
