variable "context" {
  type = object({
    project     = string
    environment = string
    Owner       = string
    ManagedBy   = string
  })
  description = "Project context containing project name and environment"
}

variable "vpc" {
  type = object({
    id                 = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
  description = "VPC configuration object containing VPC ID and subnet IDs"
}

variable "container_port" {
  description = "Port exposed by the task container to redirect traffic to."
  type        = number
}

variable "load_balancer_type" {
  description = "Type of load balancer to create (application or network)"
  type        = string
  default     = "application"
}

variable "target_group_health_check_config" {
  description = "Health check configuration for load balancer target group pointing on backend containers"
  type = object({
    interval            = number
    matcher             = number
    timeout             = number
    path                = string
    healthy_threshold   = number
    unhealthy_threshold = number
  })
}



variable "expose_admin_only" {
  description = "Whether to expose only /admin paths"
  type        = bool
}

variable "ecr_arn" {
  description = "ARN of Elastic Container Registry."
  type        = string
  default     = "*" # Add default value
}

variable "container_registry_credentials" {
  description = "Credentials for private container registry authentication"
  type = object({
    username = string
    password = string
  })
}

variable "container_image" {
  type = string
}

variable "resources" {
  description = "ECS Task configuration settings"
  type = object({
    instances = number
    cpu       = number
    memory    = number
  })
}

variable "logs" {
  description = "Logs configuration settings"
  type = object({
    group     = string
    retention = number
    prefix    = string
  })
}

variable "redis_url" {
  description = "URL for Redis connection"
  type        = string
}

variable "database_url" {
  description = "URL for database connection"
  type        = string
}

variable "jwt_secret" {
  description = "Secret used for JWT token signing. If not provided, a random secret will be generated."
  type        = string
  sensitive   = true
}

variable "cookie_secret" {
  description = "Secret used for cookie signing. If not provided, a random secret will be generated."
  type        = string
  sensitive   = true
}

variable "store_cors" {
  description = "CORS configuration for the store"
  type        = string
}

variable "admin_cors" {
  description = "CORS configuration for the admin panel"
  type        = string
}

variable "run_migrations" {
  description = "Specify medusa migrations should be run on start."
  type        = bool
}

variable "seed_create" {
  description = "Whether to create infrastructure for seeding the database"
  type        = bool
}

variable "seed_run" {
  description = "Whether to run the seed command after deployment"
  type        = bool
}

variable "seed_command" {
  description = "Command to run for seeding the database"
  type        = string
}

variable "seed_timeout" {
  description = "Timeout for the seed command"
  type        = number
}

variable "seed_fail_on_error" {
  description = "Whether to fail the deployment if the seed command fails"
  type        = bool
}

variable "admin_credentials" {
  description = "Admin user credentials. If provided, it will be used to create an admin user."
  type = object({
    email             = string
    password          = string
    generate_password = bool
  })
  default = {
    email             = ""
    password          = ""
    generate_password = true
  }
  sensitive = true

  validation {
    condition = (
      var.admin_credentials != null ? var.admin_credentials.email != "" : true
    )
    error_message = "Admin email is required when admin credentials are provided."
  }

  validation {
    condition = (
      var.admin_credentials != null ? var.admin_credentials.generate_password == true : true
    ) || (
      var.admin_credentials != null ? var.admin_credentials.password != "" : true
    )
    error_message = "Admin password is required when admin credentials are provided and generate_password is false."
  }
}

variable "extra_security_group_ids" {
  description = "List of additional security group IDs to associate with the ECS service"
  type        = list(string)
}

variable "extra_environment_variables" {
  description = "Additional environment variables to pass to the container"
  type        = map(string)
}

variable "extra_secrets" {
  description = "Additional secrets to pass to the container"
  type = map(object({
    arn = string
    key = string
  }))
}


variable "deployment_circuit_breaker" {
  description = "Deployment circuit breaker configuration"
  type = object({
    enable   = bool
    rollback = bool
  })
  default = null
}

variable "health_check_grace_period_seconds" {
  description = "The grace period for health checks in seconds"
  type        = number
  default     = null
}

variable "ecs_container_insights" {
  description = "Enable container insights for the ECS cluster"
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "enhanced", "disabled"], var.ecs_container_insights)
    error_message = "The ecs_container_insights value must be either 'enabled', 'enhanced' or 'disabled'."
  }
}
