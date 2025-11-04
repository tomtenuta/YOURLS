# Security Groups
# Environment-isolated security groups for network-level separation

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.repo}-${var.branch}-alb-sg"
  description = "ALB Security Group for ${var.branch} environment"
  vpc_id      = local.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [description, ingress, egress]
  }

  tags = merge(local.common_tags, {
    Name        = "${var.repo}-${var.branch}-alb-sg"
    Purpose     = "ALB-${var.branch}"
    NetworkTier = "public"
  })
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name        = "${var.repo}-${var.branch}-ecs-sg"
  description = "ECS Security Group for ${var.branch} environment"
  vpc_id      = local.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [description, ingress, egress]
  }

  tags = merge(local.common_tags, {
    Name        = "${var.repo}-${var.branch}-ecs-sg"
    Purpose     = "ECS-${var.branch}"
    NetworkTier = "private"
  })
}

# Security Group Rules
# ALB Rules - Public access but environment-tagged
resource "aws_security_group_rule" "alb_http" {
  count             = 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP access for ${var.branch} environment"
}

resource "aws_security_group_rule" "alb_https" {
  count             = 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS access for ${var.branch} environment"
}

resource "aws_security_group_rule" "alb_egress" {
  count             = 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.existing.cidr_block]
  security_group_id = aws_security_group.alb.id
  description       = "Outbound to VPC CIDR for ${var.branch}"
}

# ECS Rules - Strict environment isolation
resource "aws_security_group_rule" "ecs_from_alb" {
  count                    = 1
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow only ${var.branch} ALB access to ECS"
}

resource "aws_security_group_rule" "ecs_egress_internet" {
  count             = 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "HTTPS outbound for external APIs"
}

resource "aws_security_group_rule" "ecs_egress_http" {
  count             = 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "HTTP outbound for external APIs"
}

resource "aws_security_group_rule" "ecs_egress_dns" {
  count             = 0
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "DNS resolution"
}

resource "aws_security_group_rule" "ecs_egress_mysql" {
  count             = 0
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "MySQL/RDS database connections"
} 