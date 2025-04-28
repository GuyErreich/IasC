data "aws_secretsmanager_secret" "lmabda_token_generator" {
  name = "github/lmabda-token-generator"
}

data "aws_secretsmanager_secret_version" "lmabda_token_generator" {
  secret_id = data.aws_secretsmanager_secret.lmabda_token_generator.id
}