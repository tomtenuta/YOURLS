######## Simplified IAM for YOURLS on ECS ########

# Assume role policy for ECS tasks
data "aws_iam_policy_document" "ecs_exec_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS execution role
resource "aws_iam_role" "ecs_execution" {
  name               = "${var.repo}_EcsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_exec_assume.json
  tags = {
    Name    = "${var.repo}_EcsTaskExecutionRole"
    Purpose = "ECS task execution"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional ECR read-only (harmless if not using ECR)
resource "aws_iam_role_policy_attachment" "ecs_execution_ecr" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Allow execution role to retrieve SSM params/secrets for container startup
resource "aws_iam_role_policy_attachment" "ecs_execution_ssm_attach" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# Allow ECS Exec SSM messages
resource "aws_iam_role_policy_attachment" "ecs_execution_ssm_messages" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ECS task role
resource "aws_iam_role" "ecs_task" {
  name               = "${var.repo}_EcsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_exec_assume.json
  tags = {
    Name    = "${var.repo}_EcsTaskRole"
    Purpose = "ECS task runtime permissions"
  }
}

# Minimal permissions needed by YOURLS task
data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "secretsmanager:GetSecretValue",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_policy" {
  name   = "${var.repo}_EcsTaskPolicy"
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_attach" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# Allow ECS task to use SSM exec channels
resource "aws_iam_role_policy_attachment" "ecs_task_ssm_messages" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}