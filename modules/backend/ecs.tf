
locals {
  # ... (other local variables)

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
  # ... (other local variables)
}

  container_definition = {
    name           = local.container_name
    image          = var.container_image
    cpu            = var.resources.cpu
    memory         = var.resources.memory
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

resource "aws_ecs_cluster" "main" {
  name = local.prefix

  setting {
    name  = "containerInsights"
    value = var.ecs_container_insights
  }

  tags = local.tags
}

resource "aws_ecs_task_definition" "main" {
  family                    = local.prefix
  execution_role_arn        = aws_iam_role.ecs_execution.arn
  network_mode              = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                       = var.resources.cpu
  memory                    = var.resources.memory
  container_definitions     = jsonencode([local.container_definition])

  tags = local.tags
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

# modules/backend/secret.tf
resource "aws_secretsmanager_secret" "jwt_secret" {
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-jwt-secret-"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret
}

resource "aws_secretsmanager_secret" "cookie_secret" {
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-cookie-secret-"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "cookie_secret" {
  secret_id     = aws_secretsmanager_secret.cookie_secret.id
  secret_string = var.cookie_secret
}

resource "aws_secretsmanager_secret" "admin_secret" {
  count       = local.create_admin_user ? 1 : 0
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-admin-secret-"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "admin_secret" {
  count         = local.create_admin_user ? 1 : 0
  secret_id     = aws_secretsmanager_secret.admin_secret[0].id
  secret_string = jsonencode(var.admin_credentials)
}

resource "aws_secretsmanager_secret" "registry_credentials" {
  count       = var.container_registry_credentials != null ? 1 : 0
  name_prefix = "${substr(var.context.project, 0, 8)}-${substr(var.context.environment, 0, 8)}-registry-credentials-"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "registry_credentials" {
  count         = var.container_registry_credentials != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.registry_credentials[0].id
  secret_string = jsonencode(var.container_registry_credentials)
}
