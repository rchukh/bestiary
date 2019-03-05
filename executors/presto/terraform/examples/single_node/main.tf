module "prestosql" {
  source = "../../"
  environment_name = "single_node"
  coordinator_group_name = "single-coordinator"
  coordinator_group_lb_name = "single-coordinator-lb"
  worker_group_name = "single-worker"
  workers = 1
}
