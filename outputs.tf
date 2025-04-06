output "ecr_backend_url" {
  description = "The URL of the ECR repository for the backend service, if created."
  value       = var.ecr_backend_create ? module.ecr_backend[0].arn : null
}

output "backend_url" {
  description = "The URL of the backend service, either from the created module or provided externally."
  value       = var.backend_create ? module.backend[0].application_load_balancer_dns_name : var.backend_url  # CORRECTED LINE
}

