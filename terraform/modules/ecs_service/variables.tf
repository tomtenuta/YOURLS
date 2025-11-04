variable "name" {
  description = "Logical name of the service (e.g. 'lead_handler')"
  type        = string
}

variable "image_uri" {
  description = "ECR image URI for the container"
  type        = string
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
}

variable "memory" {
  description = "Task memory in MiB"
  type        = number
}

variable "port" {
  description = "Container port to expose"
  type        = number
}

variable "desired_count" {
  description = "How many tasks to keep running"
  type        = number
}

variable "cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for networking"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group" {
  description = "SG ID allowing ALB→ECS ingress"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM Role ARN for ECS task execution"
  type        = string
}

variable "task_role_arn" {
  description = "IAM Role ARN assumed by the container"
  type        = string
}

variable "region" {
  description = "AWS region (for logs)"
  type        = string
}

variable "branch" {
  description = "Deployment branch/environment (dev, staging, prod)"
  type        = string
}

variable "infrastructure_version" {
  description = "Version string that changes when infrastructure is updated (forces new task definition)"
  type        = string
  default     = "1.0.0"
}

variable "environment" {
  description = "Additional environment variables to inject into container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets to inject into container (name => { name, type }) where type is 'ssm' or 'secretsmanager'"
  type = map(object({
    name = string
    type = string
  }))
  default = {}
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/health"
}

variable "use_ecr" {
  description = "Whether image_uri points to an ECR repo (enables digest lookup)"
  type        = bool
  default     = true
}

variable "image_digest" {
  description = "Optional image digest to force task updates for non-ECR images"
  type        = string
  default     = ""
}