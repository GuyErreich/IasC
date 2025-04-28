output "secrets_arns" {
  description = "Mapping of secret names to their ARNs"
  value       = { for secret_name, secret in aws_secretsmanager_secret.github_secrets : secret_name => secret.arn }
}