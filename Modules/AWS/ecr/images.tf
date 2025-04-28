resource "docker_image" "image" {
  depends_on = [module.ecr_repos]

  for_each = var.repositories

  name = "${module.ecr_repos[each.key].repository_url}:${each.value.image.tag}"

  build {
    context    = each.value.image.context
    dockerfile = each.value.image.file
    cache_from = ["${module.ecr_repos[each.key].repository_url}:${each.value.image.tag}"]
    build_args = {
      GITHUB_RUNNER_IMAGE = "${module.ecr_repos[each.key].repository_url}:${each.value.image.tag}"
    }
  }

  triggers = each.value.image.triggers
}

resource "docker_registry_image" "image" {
  depends_on = [docker_image.image]

  for_each = docker_image.image

  name          = each.value.name
  keep_remotely = false
}
