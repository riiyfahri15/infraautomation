# ── 1. VPC Peering ───────────────────────
module "peering" {
  source = "./modules/vpc_peering"

  account_id            = var.aws_account_id
  monitoring_vpc        = module.vpc_monitoring.monitoring_vpc_id
  vpc_app               = module.vpc.vpc_id
  monitoring_rt         = module.vpc_monitoring.monitoring_rt
  vpc_rt                = module.vpc.private_route_table_id
}