locals {
  github_oidc_roles_subjects = [
    "${var.github_org}:ref:refs/heads/*",
    "${var.github_org}:ref:refs/tags/*"
  ]
}

module "github_runner_roles" {
  depends_on = [aws_lambda_layer_version.requests_layer]
  source     = "../../Modules/AWS/github_oidc_roles"

  roles = {
    GitHubActionsECSUpdateRole = {
      subjects = local.github_oidc_roles_subjects
      policies = {
        ECSServicePolicy = aws_iam_policy.ecs_update_service_policy.arn
      }
    }
    GitHubActionsSecretManagerRole = {
      subjects = local.github_oidc_roles_subjects
      policies = {
        ECRServicePolicy = aws_iam_policy.ecr_pull_accesses.arn
      }
    }
    GitHubActionsSecretManagerRole = {
      subjects = local.github_oidc_roles_subjects
      policies = {
        SecretManagerAccessesPolicy = aws_iam_policy.github_runner_secret_manager_policy.arn
      }
    }
  }
}

resource "aws_iam_policy" "github_runner_secret_manager_policy" {
  depends_on = [ module.ecs ]

  name        = "GitHubRunnerSecretManagerAccessesPolicy"
  description = "Policy for accessing specific secrets that will be used by the GitHub runner"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          data.aws_secretsmanager_secret.github_webhook_token.id,
          data.aws_secretsmanager_secret.github_runner_token.id
        ]
      },
    ]
  })
}
