locals {
  container_secret_arns = distinct(
    concat(
      [for src in local.container_secrets : src.arn],
      var.container_registry_credentials != null ? [aws_secretsmanager_secret.registry_credentials[0].arn] : []
    )
  )
}

data "aws_iam_policy_document" "ecs_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "ecs_execution_policy" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [var.ecr_arn != null ? var.ecr_arn : "*"] # Changed to handle null
    effect    = "Allow"
  }

  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
    effect    = "Allow"
  }

  dynamic "statement" {
    for_each = length(local.container_secret_arns) > 0 ? [1] : []
    content {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.container_secret_arns
      effect    = "Allow"
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name_prefix       = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-ecs-exec-" # Modified prefix
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
  tags              = local.tags
}

resource "aws_iam_policy" "ecs_execution" {
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-ecs-exec-" # Modified prefix
  policy      = data.aws_iam_policy_document.ecs_execution_policy.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution.arn
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    actions   = ["ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ecs_task" {
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-ecs-task-" # Modified prefix
  policy      = data.aws_iam_policy_document.ecs_task_policy.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task.arn
}
