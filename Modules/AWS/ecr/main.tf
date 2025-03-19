terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = var.docker_host

  dynamic "registry_auth" {
    for_each = { for key, value in var.repositories : key => value.image.auth if value.image.auth.type != "ANONYMOUS" }

    content {
      address  = registry_auth.value.registry
      username = registry_auth.value.username
      password = registry_auth.value.type == "BASIC" ? registry_auth.value.password : registry_auth.value.token
    }
  }
}
