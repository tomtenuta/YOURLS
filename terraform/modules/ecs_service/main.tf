# Get the current image digest to force task definition updates when image changes
locals {
  _repo_name = try(split("/", split(":", var.image_uri)[0])[1], "")
  _image_tag = try(split(":", var.image_uri)[1], "latest")
}

data "aws_ecr_image" "this" {
  count           = var.use_ecr ? 1 : 0
  repository_name = local._repo_name
  image_tag       = local._image_tag
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg-${var.port}"
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"                # <–– force IP targets for Fargate

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  # Enable connection draining with shorter timeout
  deregistration_delay = 30          # Reduced from default 300s

  # Enable stickiness for better user experience (optional)
  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 3600           # 1 hour
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name         = var.name
    image        = var.image_uri
    cpu          = var.cpu
    memory       = var.memory
    essential    = true
    portMappings = [{ containerPort = var.port, hostPort = var.port, protocol = "tcp" }]

    environment = concat([
      { name = "PORT", value = tostring(var.port) },
      { name = "HOST", value = "0.0.0.0" },
      { name = "WORKERS", value = "1" },
      { name = "AWS_DEFAULT_REGION", value = var.region },
      { name = "AWS_REGION", value = var.region },
      { name = "BRANCH", value = var.branch },
      # Force task definition update when image changes by adding image digest
      { name = "IMAGE_DIGEST", value = var.use_ecr ? coalesce(try(data.aws_ecr_image.this[0].image_digest, ""), "") : var.image_digest },
      # Force task definition update when infrastructure changes
      { name = "INFRA_VERSION", value = var.infrastructure_version }
    ], [for k, v in var.environment : { name = k, value = v }])

    secrets = [for k, v in var.secrets : {
      name      = k
      valueFrom = v.type == "ssm" ? data.aws_ssm_parameter.secret[k].arn : data.aws_secretsmanager_secret.secret[k].arn
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${var.name}"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  
  # Force replacement when key infrastructure changes
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count
  health_check_grace_period_seconds = 300
  enable_execute_command           = true
  
  # AWS native blue/green deployment (default behavior)
  deployment_maximum_percent         = 200  # AWS default for safe deployments
  deployment_minimum_healthy_percent = 100  # Keep existing tasks running during deployment
  
  # AWS built-in circuit breaker with automatic rollback
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [var.ecs_security_group]
    assign_public_ip = false  # Secure: Private subnets use NAT gateway for outbound
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.port
  }

  # Force new deployment when infrastructure changes
  force_new_deployment = true

  depends_on = [aws_lb_target_group.this]
}

# Null resource to force ECS deployment when infrastructure changes
resource "null_resource" "force_deployment" {
  # This will change whenever infrastructure version changes
  triggers = {
    infrastructure_version = var.infrastructure_version
    image_digest          = var.use_ecr ? try(data.aws_ecr_image.this[0].image_digest, "") : var.image_digest
    timestamp             = timestamp()
  }

  # Force ECS to update service after task definition changes
  provisioner "local-exec" {
    command = <<-EOT
      echo "Forcing new deployment for ${var.name} due to infrastructure changes..."
      aws ecs update-service \
        --cluster ${var.cluster_id} \
        --service ${var.name} \
        --force-new-deployment \
        --region ${var.region} \
        --output json > /dev/null 2>&1 || true
    EOT
  }

  depends_on = [
    aws_ecs_service.this,
    aws_ecs_task_definition.this
  ]
}

# Look up existing secrets (do not manage secrets here)
data "aws_ssm_parameter" "secret" {
  for_each        = { for k, v in var.secrets : k => v if v.type == "ssm" }
  name            = each.value.name
  with_decryption = true
}

data "aws_secretsmanager_secret" "secret" {
  for_each = { for k, v in var.secrets : k => v if v.type == "secretsmanager" }
  name     = each.value.name
}

# Output the task definition ARN for reference
output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}
