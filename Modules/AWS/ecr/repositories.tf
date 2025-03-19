module "ecr_repos" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

  for_each = var.repositories

  repository_name = each.value.group != null ? "${each.value.group}/${each.key}" : each.key

  repository_image_scan_on_push   = each.value.image_scan_on_push
  repository_image_tag_mutability = each.value.image_tag_mutability
  repository_lifecycle_policy = jsonencode({
    rules = each.value.lifecycle_policy_rules
  })

  repository_force_delete = true
}