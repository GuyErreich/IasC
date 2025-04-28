locals {
  github_oidc_roles_subjects = [
    "${var.github_org}:ref:refs/heads/*",
    "${var.github_org}:ref:refs/tags/*"
  ]
}

module "github_oidc_roles" {
  source = "../Modules/AWS/github_oidc_roles"

  depends_on = [ aws_iam_policy.github_secret_manager_policy ]

  roles = {
    ImagesRepoActionsSecretManagerRole = {
      subjects = local.github_oidc_roles_subjects
      policies = {
        SecretManagerAccessesPolicy = aws_iam_policy.github_secret_manager_policy.arn
      }
    }
  }
}

resource "aws_iam_policy" "github_secret_manager_policy" {
  depends_on = [ module.github_secret_manager ]

  name        = "GitHubSecretManagerAccessesPolicy"
  description = "Policy for accessing specific secrets that will be used by the GitHub"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = values(module.github_secret_manager.secrets_arns)
      },
    ]
  })
}
