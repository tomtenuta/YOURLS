// modules/alb_routes/main.tf
variable "listener_arn" {
  type        = string
  description = "ARN of the ALB listener to attach rules to"
}

variable "target_group_arn" {
  type        = string
  description = "Target group ARN for the FastAPI monolith"
}

variable "routes" {
  type        = list(string)
  description = "List of base paths (e.g. \"/prod/lead_handler\") to forward"
}

resource "aws_lb_listener_rule" "app_routes" {
  for_each     = { for idx, path in var.routes : idx => path }
  listener_arn = var.listener_arn
  # use a low-ish base so these live above your other job rules
  priority     = 1000 + each.key

  action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  condition {
    path_pattern {
      values = [
        each.value,              // exact match
        "${each.value}/*"        // and "sub-paths"
      ]
    }
  }
}
