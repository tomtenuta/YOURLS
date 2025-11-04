output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "URL to hit your ALB"
}

output "ecs_cluster_id" {
  value       = aws_ecs_cluster.main.id
  description = "The ECS cluster"
}

output "ecs_security_group_id" {
  value       = aws_security_group.ecs.id
  description = "ECS service security group ID"
}

output "yourls_health_url" {
  value       = "http://${aws_lb.app.dns_name}/yourls-api.php?action=version&format=json"
  description = "Health check URL for YOURLS"
}

output "yourls_health_url_https" {
  value       = var.domain_name != "" ? "https://${var.domain_name}/yourls-api.php?action=version&format=json" : "HTTPS not configured"
  description = "HTTPS Health check URL for YOURLS"
}

output "vpc_id" {
  value       = local.vpc_id
  description = "VPC ID used by terraform"
}

## Removed legacy monolith outputs

## Removed legacy API endpoints output

output "infrastructure_version" {
  description = "Current infrastructure version (changes trigger ECS blue/green deployment)"
  value       = local.infrastructure_version
}

## Removed deployment trigger info tied to monolith image
