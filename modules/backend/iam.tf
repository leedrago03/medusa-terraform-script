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
    resources = [var.ecr_arn]
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
  name_prefix          = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-ecs-exec-" # Modified prefix
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
  tags                 = local.tags
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

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "s3-object-lambda:*"
    ]
    resources = [
      aws_s3_bucket.uploads.arn,
      "${aws_s3_bucket.uploads.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-s3-access-" # Modified prefix
  policy      = data.aws_iam_policy_document.s3_access.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_access" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role" "ecs_task" {
  name_prefix          = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-ecs-task-" # Modified prefix
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags                 = local.tags
}

resource "aws_iam_user_policy_attachment" "s3_access" {
  user       = aws_iam_user.medusa_s3.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_user" "medusa_s3" {
  name = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-s3-user" # Modified prefix
  tags = local.tags
}

resource "aws_iam_access_key" "medusa_s3" {
  user = aws_iam_user.medusa_s3.name
}

data "aws_iam_policy_document" "lambda_seed_assume_role" {
  count = var.seed_create ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "lambda_seed_policy" {
  count = var.seed_create ? 1 : 0
  statement {
    actions = ["ecs:ListTasks", "ecs:ExecuteCommand"]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [aws_ecs_cluster.main.arn]
    }
    effect = "Allow"
  }
  statement {
    actions   = ["ssm:GetCommandInvocation"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role" "lambda_seed" {
  count                = var.seed_create ? 1 : 0
  name_prefix          = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-lambda-seed-" # Modified prefix
  assume_role_policy = data.aws_iam_policy_document.lambda_seed_assume_role[0].json
  tags                 = local.tags
}

resource "aws_iam_policy" "lambda_seed" {
  count       = var.seed_create ? 1 : 0
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-lambda-seed-" # Modified prefix
  policy      = data.aws_iam_policy_document.lambda_seed_policy[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_seed" {
  count       = var.seed_create ? 1 : 0
  role        = aws_iam_role.lambda_seed[0].name
  policy_arn = aws_iam_policy.lambda_seed[0].arn
}
