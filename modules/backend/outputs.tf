

output "admin_secret_arn" {
  value = local.create_admin_user ? aws_secretsmanager_secret.admin_secret[0].arn : null
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}
output "application_load_balancer_dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.main.dns_name
}
