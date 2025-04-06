data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  context = {
    project     = var.project
    environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
  vpc = {
    id                 = var.vpc_create ? module.vpc[0].id : var.vpc_id
    public_subnet_ids  = var.vpc_create ? module.vpc[0].public_subnet_ids : var.public_subnet_ids
    private_subnet_ids = var.vpc_create ? module.vpc[0].private_subnet_ids : var.private_subnet_ids
  }
  backend = {
    ecr_arn = var.ecr_backend_create ? module.ecr_backend[0].arn : var.backend_ecr_arn
    url     = var.backend_create ? module.backend[0].url : var.backend_url
  }
}

module "ecr_backend" {
  source = "./modules/ecr"
  count  = var.ecr_backend_create ? 1 : 0

  context = local.context

  name            = "backend"
  retention_count = var.ecr_backend_retention_count
}

module "vpc" {
  source = "./modules/vpc"
  count  = var.vpc_create ? 1 : 0

  context = local.context

  cidr_block = var.cidr_block
  az_count   = var.az_count
}

module "elasticache" {
  source = "./modules/elasticache"
  count  = var.elasticache_create ? 1 : 0

  context = local.context
  vpc     = local.vpc

  node_type            = var.elasticache_node_type
  nodes_num            = var.elasticache_nodes_num
  redis_engine_version = var.elasticache_redis_engine_version
  port                 = var.elasticache_port
}

module "rds" {
  source = "./modules/rds"
  count  = var.rds_create ? 1 : 0

  context = local.context
  vpc     = local.vpc

  username          = var.rds_username
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = var.rds_engine_version
  port              = var.rds_port
}

module "backend" {
  source = "./modules/backend"
  count  = var.backend_create ? 1 : 0

  context = local.context
  vpc     = local.vpc

  container_port                   = var.backend_container_port
  target_group_health_check_config = var.backend_target_group_health_check_config
  expose_admin_only                = var.backend_expose_admin_only

  ecr_arn                        = local.backend.ecr_arn
  container_registry_credentials = var.backend_container_registry_credentials
  container_image                = var.backend_container_image
  resources                      = var.backend_resources
  logs                           = var.backend_logs

  redis_url    = var.elasticache_create ? module.elasticache[0].url : var.redis_url
  database_url = var.rds_create ? module.rds[0].url : var.database_url

  jwt_secret    = var.backend_jwt_secret
  cookie_secret = var.backend_cookie_secret
  store_cors    = var.backend_store_cors
  admin_cors    = var.backend_admin_cors

  run_migrations     = var.backend_run_migrations
  seed_create        = var.backend_seed_create
  seed_run           = var.backend_seed_run
  seed_command       = var.backend_seed_command
  seed_timeout       = var.backend_seed_timeout
  seed_fail_on_error = var.backend_seed_fail_on_error
  admin_credentials  = var.backend_admin_credentials

  extra_security_group_ids = concat(
    var.rds_create ? [module.rds[0].client_security_group_id] : [],
    var.elasticache_create ? [module.elasticache[0].client_security_group_id] : [],
    var.backend_extra_security_group_ids,
  )
  extra_environment_variables = var.backend_extra_environment_variables
  extra_secrets               = var.backend_extra_secrets
}