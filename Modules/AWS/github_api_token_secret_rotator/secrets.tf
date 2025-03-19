resource "aws_secretsmanager_secret" "github_secrets" {
  for_each = var.secrets

  name                    = "${local.secret_prefix}${each.key}"
  recovery_window_in_days = 0
}

# Attach rotation for each secret with custom rotation time
resource "aws_secretsmanager_secret_rotation" "github_secrets_rotation" {
  depends_on = [aws_secretsmanager_secret.github_secrets]

  for_each = var.secrets

  secret_id           = aws_secretsmanager_secret.github_secrets[each.key].id
  rotation_lambda_arn = module.lambda_function.lambda_function_arn

  rotation_rules {
    automatically_after_days = each.value.rotation_days
  }

  rotate_immediately = true
}