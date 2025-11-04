# Main Terraform Configuration
# Core ECS services and application deployment

# This file now focuses only on the core application services
# Supporting infrastructure is organized in separate files:
# - vpc_data_sources.tf: VPC and subnet discovery
# - locals.tf: Configuration and computed values  
# - security_groups.tf: Security group definitions
# - iam.tf: IAM roles and policies
# - alb.tf: Load balancer and SSL
# - alb_routing_generated.tf: ALB routing rules (dynamically generated)
# - vpc_peering.tf: Database connectivity

# Core ECS Services
# Main application deployment components

## Removed legacy monolith module

# YOURLS service (URL shortener)
module "yourls" {
  source             = "./modules/ecs_service"
  name               = "yourls-${var.branch}"
  image_uri          = var.yourls_image_uri
  use_ecr            = false
  image_digest       = var.yourls_image_digest
  cpu                = 256
  memory             = 512
  port               = 8080
  desired_count      = 1

  cluster_id         = aws_ecs_cluster.main.id
  vpc_id             = local.vpc_id
  private_subnets    = local.private_subnet_ids
  ecs_security_group = aws_security_group.ecs.id

  execution_role_arn = local.execution_role_arn
  task_role_arn      = local.task_role_arn

  region             = var.aws_region
  branch             = var.branch
  infrastructure_version = local.infrastructure_version

  health_check_path  = "/images/yourls-logo.svg"

  environment = {
    YOURLS_SITE        = "https://cntently.com"
    YOURLS_DB_HOST     = var.yourls_db_host
    YOURLS_DB_NAME     = var.yourls_db_name
    YOURLS_PRIVATE     = "false"
    YOURLS_NOSTATS     = "true"
    YOURLS_UNIQUE_URLS = "false"
  }

  secrets = {
    YOURLS_DB_USER = { name = var.yourls_db_user_param, type = "ssm" }
    YOURLS_DB_PASS = { name = var.yourls_db_pass_param, type = "ssm" }
    YOURLS_USER    = { name = var.yourls_admin_user_param, type = "ssm" }
    YOURLS_PASS    = { name = var.yourls_admin_pass_param, type = "ssm" }
    YOURLS_COOKIEKEY = { name = var.yourls_cookie_key_param, type = "ssm" }
  }

  depends_on = [aws_lb_listener.http]
}

## Removed generic ecs_services module
