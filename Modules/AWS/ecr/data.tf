data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ecr_image" "images" {
  depends_on = [module.ecr_repos["*"], docker_registry_image.image["*"]]

  for_each = var.repositories

  repository_name = module.ecr_repos[each.key].repository_name
  image_tag       = each.value.image.tag
}