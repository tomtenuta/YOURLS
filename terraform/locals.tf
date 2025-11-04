locals {
  # Environment configuration
  environment = var.branch
  
  # VPC Configuration - Use existing VPC
  vpc_id = "vpc-0c23f21054cebe40e"  # Existing working VPC
  
  # Industry Standard: Use existing VPC with dynamic subnet discovery
  # Environment isolation is achieved through security groups and resource naming
  
  # Common tags
  common_tags = {
    Environment = local.environment
    Project     = var.repo
    ManagedBy   = "terraform"
    Owner       = "yourls"
  }
  
  # Security group configurations (immutable descriptions)
  security_groups = {
    alb = {
      name        = "${var.repo}-alb-sg"
      description = "ALB Security Group"
      rules = {
        http_ingress = {
          type        = "ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP access"
        }
        https_ingress = {
          type        = "ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS access"
        }
        all_egress = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      }
    }
    ecs = {
      name        = "${var.repo}-ecs-sg"
      description = "ECS Security Group"
      rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          source_security_group_id = true  # Will be replaced with actual SG ID
          description              = "Allow ALB access to ECS"
        }
        all_egress = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      }
    }
  }
  
  # Remove legacy monolith ECR image reference
  
  # ECS configuration
  # Removed legacy ecs_config for monolith
  
  # ALB configuration
  alb_config = {
    internal = false
    type     = "application"
    idle_timeout = 60
    enable_deletion_protection = false
  }
  
  # Certificate configuration
  certificate_config = {
    domain_name       = var.domain_name != "" ? "*.${var.domain_name}" : ""
    validation_method = "DNS"
  }
  
  # Use provided domain_name/root_domain inputs; no environment domain mapping
  current_domain = var.domain_name != "" ? var.domain_name : var.root_domain
  
  # SSL certificate configuration
  # Use the value from tfvars - SSL certificates are available for all environments
  create_certificate = var.create_certificate

  # IAM role ARNs for module wiring
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn
  
  # Dynamic subnet discovery from existing VPC
  # Get the internet gateway ID if it exists
  igw_id = data.aws_internet_gateway.existing_igw.id
  
  # Public subnets (from variables)
  public_subnet_ids = var.public_subnet_ids
  
  # Private subnets (from variables)
  private_subnet_ids = var.private_subnet_ids
  
  # Get route table IDs for private subnets
  private_route_table_ids = data.aws_route_tables.existing_all.ids
  
  # Infrastructure version tracking
  # This hash changes when key infrastructure components are modified
  # Forcing ECS to create new task definitions and trigger blue/green deployments
  infrastructure_version = md5(jsonencode({
    vpc_config              = local.vpc_id
    subnet_config           = concat(local.public_subnet_ids, local.private_subnet_ids)
    security_group_rules    = local.security_groups
    iam_execution_role      = aws_iam_role.ecs_execution.arn
    iam_task_role           = aws_iam_role.ecs_task.arn
    alb_config             = local.alb_config
    certificate_enabled    = local.create_certificate
    environment_domain     = local.current_domain
    vpc_peering_enabled    = true
    database_access        = data.aws_vpc.database_vpc.id
    # Add any other infrastructure components you want to track
  }))
} 