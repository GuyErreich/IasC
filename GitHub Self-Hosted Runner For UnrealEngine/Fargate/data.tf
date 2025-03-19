data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_regions" "available" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "github_webhook_token" {
  name = "github/webhook_token" # Replace with the name of your secret
}

data "aws_secretsmanager_secret_version" "github_webhook_token" {
  secret_id = data.aws_secretsmanager_secret.github_webhook_token.id
}

data "aws_secretsmanager_secret" "github_runner_token" {
  name = "github/runner_token"
}

data "aws_secretsmanager_secret_version" "github_runner_token" {
  secret_id = data.aws_secretsmanager_secret.github_runner_token.id
}