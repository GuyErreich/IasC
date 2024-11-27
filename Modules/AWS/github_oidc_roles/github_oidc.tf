# Module: IAM GitHub OIDC Provider
module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.0"
}

# Module: IAM GitHub OIDC Role for ECS Service Update
module "iam_github_oidc_ecs_role" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version       = "~> 5.0"

  for_each      = var.roles

  name          = each.key
  provider_url  = module.iam_github_oidc_provider.url
  subjects      = each.value.subjects
  policies      = each.value.policies
}
