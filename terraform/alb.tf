# Application Load Balancer and Routing
# Environment-isolated ALB with SSL support

# KMS Key for CloudWatch Logs encryption
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.repo}-cloudwatch-logs-kms"
  })
}

resource "aws_kms_alias" "cloudwatch_logs" {
  count         = var.create_kms_alias ? 1 : 0
  name          = "alias/${var.repo}-cloudwatch-logs-${var.branch}"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# Data sources for KMS policy
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudWatch Log Groups with optimized retention
resource "aws_cloudwatch_log_group" "yourls" {
  name              = "/ecs/yourls-${var.branch}"
  retention_in_days = var.branch == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(local.common_tags, {
    Application = "yourls"
    Environment = var.branch
  })
}

# Log groups for other ECS services
## Removed generic ecs_services log groups

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.repo}-cluster"
  tags = local.common_tags
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${var.repo}-${var.branch}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids

  # Handle existing ALBs gracefully during environment switching
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.repo}-${var.branch}-alb"
  })
}

# Look up existing SSL certificate
data "aws_acm_certificate" "app" {
  count       = local.create_certificate ? 1 : 0
  domain      = local.current_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

# HTTPS Listener (Environment-Specific)
resource "aws_lb_listener" "https" {
  count             = local.create_certificate ? 1 : 0
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.app[0].arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

# HTTP Listener (redirect to HTTPS if enabled)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.create_certificate ? "redirect" : "fixed-response"
    
    dynamic "redirect" {
      for_each = local.create_certificate ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = !local.create_certificate ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Development ALB - Use HTTP endpoints"
        status_code  = "200"
      }
    }
  }
} 