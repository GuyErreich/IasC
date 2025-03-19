locals {
  ecr_conf = {
    image_scan_on_push   = false
    image_tag_mutability = "MUTABLE"
    lifecycle_policy_rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  }

  nginx_conf = {
    port     = "3128"
    resolver = "169.254.169.253"
    allowed_upstreams = [
      #Task metadata version 2
      "169.254.170.2"
    ]
    allowed_server_names = [
      #Needed for essential operations
      "api.github.com",
      "github.com",
      "*.actions.githubusercontent.com",
      #Needed for downloading actions
      "codeload.github.com",
      "pkg.actions.githubusercontent.com",
      #Needed for publishing immutable actions
      "ghcr.io",
      #Needed for uploading/downloading job summaries, logs, workflow artifacts, and caches
      "results-receiver.actions.githubusercontent.com",
      "*.blob.core.windows.net",
      #Needed for runner version updates
      "objects.githubusercontent.com",
      "objects-origin.githubusercontent.com",
      "github-releases.githubusercontent.com",
      "github-registry-files.githubusercontent.com",
      #Needed for retrieving OIDC tokens
      "*.actions.githubusercontent.com",
      #Needed for downloading or publishing packages or containers to GitHub Packages
      "*.pkg.github.com",
      "pkg-containers.githubusercontent.com",
      "ghcr.io",
      #Needed for Git Large File Storage
      "github-cloud.githubusercontent.com",
      "github-cloud.s3.amazonaws.com",
      #Needed for jobs for Dependabot updates
      "dependabot-actions.githubapp.com"
    ]
  }
}

module "ecr" {
  source = "../../Modules/AWS/ecr"

  repositories = {
    github-runner = {
      group                  = "ci-cd"
      image_scan_on_push     = local.ecr_conf.image_scan_on_push
      image_tag_mutability   = local.ecr_conf.image_tag_mutability
      lifecycle_policy_rules = local.ecr_conf.lifecycle_policy_rules
      image = {
        file    = "basic_linux_x64.dockerfile"
        context = "../Images/GitHub_Runners"
        tag     = "basic-linux-22.04-x64"
        triggers = {
          context_sha1 = sha1(join("", [for f in fileset("../Images/GitHub_Runners", "**") : filesha1("../Images/GitHub_Runners/${f}")]))
        }
      }
    }

    unreal-runner = {
      group                  = "ci-cd"
      image_scan_on_push     = local.ecr_conf.image_scan_on_push
      image_tag_mutability   = local.ecr_conf.image_tag_mutability
      lifecycle_policy_rules = local.ecr_conf.lifecycle_policy_rules
      image = {
        file    = "unreal_engine_linux_x64.dockerfile"
        context = "../Images/UnrealEngine"
        tag     = "basic-linux-22.04-x64-ue-5.4.4"
        auth = {
          registry  = "ghcr.io"
          type      = "TOKEN"
          username  = "USERNAME"
          token     = ""
        }
        depends_on = ["github-runner"]
        triggers = {
          context_sha1 = sha1(join("", [for f in fileset("../Images/UnrealEngine", "**") : filesha1("../Images/UnrealEngine/${f}")]))
        }
      }
    }

    github-runner-nginx = {
      group                  = "ci-cd"
      image_scan_on_push     = local.ecr_conf.image_scan_on_push
      image_tag_mutability   = local.ecr_conf.image_tag_mutability
      lifecycle_policy_rules = local.ecr_conf.lifecycle_policy_rules
      image = {
        file    = "Dockerfile"
        context = "../Images/NGINX"
        tag     = "latest"
        triggers = {
          context_sha1 = sha1(join("", [for f in fileset("../Images/NGINX", "**") : filesha1("../Images/NGINX/${f}")]))
        }
      }
    }
  }
}

resource "local_file" "nginx_config" {
  filename        = "../Images/NGINX/nginx.conf"
  file_permission = 0644

  content = templatefile("${path.cwd}/resources/nginx.conf", {
    port                 = local.nginx_conf.port
    resolver             = local.nginx_conf.resolver
    allowed_upstreams    = distinct(local.nginx_conf.allowed_upstreams)
    allowed_server_names = distinct(local.nginx_conf.allowed_server_names)
  })
}