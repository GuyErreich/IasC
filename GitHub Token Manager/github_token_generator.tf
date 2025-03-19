module "github_secret_manager" {
  source               = "../Modules/AWS/github_api_token_secret_rotator"
  lambda_function_name = "github-token-rotator"
  github_owner         = var.github_org
  github_token         = jsondecode(data.aws_secretsmanager_secret_version.lmabda_token_generator.secret_string)["Token"]

  secrets = {
    package_access = {
      github_secret_name = "package-write-access",
      rotation_days      = 30,
      github_permissions = {
        "packages" = "write"
      }
    }
  }
}