module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  depends_on = [aws_secretsmanager_secret.github_secrets]

  function_name = var.lambda_function_name
  description   = "Rotates GitHub secrets in AWS Secrets Manager"
  handler       = "generate_github_token.lambda_handler"
  runtime       = "python3.12"

  source_path = [
    "${path.module}/Lambda"
  ]

  environment_variables = {
    GITHUB_OWNER  = var.github_owner
    GITHUB_TOKEN  = var.github_token
    SECRET_CONFIG = jsonencode(var.secrets)
    SECRET_PREFIX = local.secret_prefix
  }

  publish = true

  create_role = true

  allowed_triggers = {
    for secret_name, secret in aws_secretsmanager_secret.github_secrets :
    "SecretsManagerTrigger-${secret_name}" => {
      principal  = "secretsmanager.amazonaws.com"
      source_arn = secret.arn
    }
  }

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue", "secretsmanager:DescribeSecret"],
        Resource = values(aws_secretsmanager_secret.github_secrets)[*].arn
      }
    ]
  })

  tags = {
    Name = var.lambda_function_name
  }
}