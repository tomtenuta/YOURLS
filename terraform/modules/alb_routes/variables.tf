variable "listener_arn" {
  description = "ARN of the ALB listener to attach rules to"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for the monolith service"
  type        = string
}

variable "routes" {
  description = "List of paths (e.g. '/asana_handler') for which to create listener rules"
  type        = list(string)
}