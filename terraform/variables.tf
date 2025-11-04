## Removed ECR account variable (not needed for YOURLS Docker Hub image)

variable "aws_profile" {
  description = "AWS CLI profile to use (optional)"
  type        = string
  default     = ""
}

variable "repo" {
  type        = string
  description = "Name of the repository (used for naming)"
}

variable "branch" {
  type        = string
  description = "Git branch or tag to deploy (used as image tag and naming)"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
}

# VPC configuration removed - now using centralized autom8-app-vpc with fixed subnets

## Removed generic ecs_services and app_routes variables

variable "domain_name" {
  type        = string
  description = "Domain name for HTTPS certificate (optional)"
  default     = ""
}

variable "create_certificate" {
  type        = bool
  description = "Whether to create an ACM certificate"
  default     = false
}

# YOURLS specific variables
variable "yourls_image_uri" {
  description = "Docker image for YOURLS (Docker Hub or ECR)"
  type        = string
  default     = "yourls/yourls:latest"
}

variable "yourls_image_digest" {
  description = "Optional image digest to force deploys for non-ECR images"
  type        = string
  default     = ""
}

variable "yourls_db_host" {
  description = "RDS endpoint hostname for YOURLS"
  type        = string
}

variable "yourls_db_name" {
  description = "YOURLS database name"
  type        = string
  default     = "yourls"
}

variable "yourls_db_user_param" {
  description = "SSM parameter name for YOURLS DB username"
  type        = string
}

variable "yourls_db_pass_param" {
  description = "SSM parameter name for YOURLS DB password"
  type        = string
}

# YOURLS admin bootstrap parameters
variable "yourls_admin_user_param" {
  description = "SSM parameter name for YOURLS admin username"
  type        = string
}

variable "yourls_admin_pass_param" {
  description = "SSM parameter name for YOURLS admin password"
  type        = string
}

variable "yourls_cookie_key_param" {
  description = "SSM parameter name for YOURLS cookie key"
  type        = string
}

variable "root_domain" {
  description = "Root domain used for short URLs (e.g., cntently.com)"
  type        = string
  default     = "cntently.com"
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "manage_sg_rules" {
  description = "Whether to create security group rule resources (disable if rules pre-exist)"
  type        = bool
  default     = true
}

variable "create_kms_alias" {
  description = "Whether to create a KMS alias for the CloudWatch logs key"
  type        = bool
  default     = true
}
