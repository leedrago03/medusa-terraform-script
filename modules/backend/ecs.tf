# modules/backend/ecs.tf

locals {
  container_name = "backend"

  container_default_env = merge(
    {
      DATABASE_URL : var.database_url
    },
    {
      S3_FILE_URL : aws_s3_bucket.uploads.bucket_regional_domain_name,
      S3_BUCKET    : aws_s3_bucket.uploads.id,
      S3_REGION    : aws_s3_bucket.uploads.region,
      S3_ENDPOINT  : "https://s3.${aws_s3_bucket.uploads.region}.amazonaws.com"
    },
    var.redis_url != null ? { REDIS_URL : var.redis_url, CACHE_REDIS_URL : var.redis_url, EVENTS_REDIS_URL : var.redis_url, WE_REDIS_URL : var.redis_url } : {},
    var.store_cors != null ? { STORE_CORS : var.store_cors } : {},
    var.admin_cors != null ? { ADMIN_CORS : var.admin_cors } : {},
    var.run_migrations != null ? { MEDUSA_RUN_MIGRATION : tostring(var.run_migrations) } : {},
    local.create_admin_user != null ? { MEDUSA_CREATE_ADMIN_USER : tostring(local.create_admin_user) } : {}
  )
  container_env = merge(local.container_default_env, var.extra_environment_variables)

  container_default_secrets = merge(
    {
      JWT_SECRET : {
        arn = aws_secretsmanager_secret.jwt_secret.arn
        key = "::${aws_secretsmanager_secret_version.jwt_secret.version_id}"
      },
      COOKIE_SECRET : {
        arn = aws_secretsmanager_secret.cookie_secret.arn
        key = "::${aws_secretsmanager_secret_version.cookie_secret.version_id}"
      },
    },
    local.create_admin_user ? {
      MEDUSA_ADMIN_EMAIL : {
        arn = aws_secretsmanager_secret.admin_secret[0].arn
        key = "email::${aws_secretsmanager_secret_version.admin_secret[0].version_id}"
      },
      MEDUSA_ADMIN_PASSWORD : {
        arn = aws_secretsmanager_secret.admin_secret[0].arn
        key = "password::${aws_secretsmanager_secret_version.admin_secret[0].version_id}"
      }
    } : {}
  )
  container_secrets = merge(local.container_default_secrets, var.extra_secrets)

  container_definition = {
    name               = local.container_name
    image              = var.container_image
    cpu                = var.resources.cpu
    memory             = var.resources.memory
    portMappings = [
      {
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region"        = data.aws_region.current.name,
        "awslogs-group"         = "${local.prefix}${var.logs.group}",
        "awslogs-stream-prefix" = var.logs.prefix
      }
    }
    environment = [for name, value in local.container_env : {
      name  = name
      value = value
    }]
    secrets = [for name, src in local.container_secrets : {
      name      = name
      valueFrom = "${src.arn}:${src.key}"
    }],
    repositoryCredentials = var.container_registry_credentials != null ? {
      credentialsParameter = aws_secretsmanager_secret.registry_credentials[0].arn
    } : null
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ],
  })
}

resource "aws_iam_policy" "ecs_task_s3_policy" {
  name        = "${local.prefix}-ecs-task-s3-policy"
  description = "S3 policy for ECS task"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.uploads.id}",
          "arn:aws:s3:::${aws_s3_bucket.uploads.id}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_s3_policy_attachment" {
  name       = "ecs-task-s3-policy-attachment"
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_s3_policy.arn
}

resource "aws_iam_policy" "ecs_task_rds_policy" {
  name        = "${local.prefix}-ecs-task-rds-policy"
  description = "RDS policy for ECS task"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:Describe*",
          "rds:Connect"
        ],
        Resource = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${module.rds[0].aws_db_instance.postgres.id}"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_rds_policy_attachment" {
  name       = "ecs-task-rds-policy-attachment"
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_rds_policy.arn
}

resource "aws_iam_policy" "ecs_task_secrets_policy" {
  name        = "${local.prefix}-ecs-task-secrets-policy"
  description = "Secrets Manager policy for ECS task"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = [
          "${aws_secretsmanager_secret.jwt_secret.arn}",
          "${aws_secretsmanager_secret.cookie_secret.arn}",
          "${aws_secretsmanager_secret.admin_secret[0].arn}",
          "${aws_secretsmanager_secret.registry_credentials[0].arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_secrets_policy_attachment" {
  name       = "ecs-task-secrets-policy-attachment"
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_secrets_policy.arn
}

resource "aws_ecs_cluster" "main" {
  name = local.prefix

  setting {
    name  = "containerInsights"
    value = var.ecs_container_insights
  }

  tags = local.tags
}

resource "aws_ecs_task_definition" "main" {
  family               = local.prefix
  execution_role_arn   = aws_iam_role.ecs_execution.arn
  task_role_arn        = aws_iam_role.ecs_task_role.arn # Reference the IAM role
  network_mode         = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                  = var.resources.cpu
  memory               = var.resources.memory
  container_definitions = jsonencode([local.container_definition])
  tags                 = local.tags
}

resource "aws_ecs_service" "main" {
  name            = local.prefix
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.resources.instances
  enable_execute_command = true
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  launch_type     = "FARGATE"
  network_configuration {
    security_groups = concat([aws_security_group.ecs.id], var.extra_security_group_ids)
    subnets         = var.vpc.private_subnet_ids
  }
  load_balancer {
    container_name  = local.container_name
    target_group_arn = aws_lb_target_group.main.arn
    container_port  = var.container_port
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_circuit_breaker != null ? [1] : []
    content {
      enable  = var.deployment_circuit_breaker.enable
      rollback = var.deployment_circuit_breaker.rollback
    }
  }

  wait_for_steady_state = true

  tags = local.tags
}
