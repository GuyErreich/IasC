variable "repositories" {
  type = map(object({
    group                  = optional(string, null)
    image_scan_on_push     = bool
    image_tag_mutability   = optional(string, "MUTABLE") # can be ("MUTABLE", "IMMUTABLE")
    lifecycle_policy_rules = list(any)
    image = object({
      file    = string
      context = string
      tag     = string
      auth = optional(object({
        registry = optional(string, "docker.io")
        type     = optional(string, "ANONYMOUS") # can be ("ANONYMOUS", "BASIC", "TOKEN")
        username = optional(string)
        password = optional(string)
        token    = optional(string)
      }), { registry = "docker.io", type = "ANONYMOUS" })
      triggers   = map(string)
      depends_on = optional(list(string), [])
    })
  }))

  validation {
    condition     = alltrue([for repo in values(var.repositories) : contains(["MUTABLE", "IMMUTABLE"], repo.image_tag_mutability)])
    error_message = "image_tag_mutability must be either 'MUTABLE' or 'IMMUTABLE'."
  }

  validation {
    condition     = alltrue([for repo in values(var.repositories) : contains(["ANONYMOUS", "BASIC", "TOKEN"], repo.image.auth.type)])
    error_message = "auth.type must be one of 'ANONYMOUS', 'BASIC', or 'TOKEN'."
  }

  validation {
    condition     = alltrue([for repo in values(var.repositories) : repo.image.auth.type != "BASIC" || (repo.image.auth.username != null && repo.image.auth.password != null)])
    error_message = "For 'BASIC' authentication, 'username' and 'password' must be provided."
  }

  validation {
    condition     = alltrue([for repo in values(var.repositories) : repo.image.auth.type != "TOKEN" || repo.image.auth.token != null])
    error_message = "For 'TOKEN' authentication, 'TOKEN' must be provided."
  }

  validation {
    condition     = alltrue([for repo in values(var.repositories) : length(repo.lifecycle_policy_rules) == 0 || alltrue([for rule in repo.lifecycle_policy_rules : can(rule.rulePriority) && can(rule.action) && can(rule.selection)])])
    error_message = "Each lifecycle policy rule must contain 'rulePriority', 'action', and 'selection'."
  }

  validation {
    condition     = alltrue([for repo in values(var.repositories) : alltrue([for dep in repo.image.depends_on : contains(keys(var.repositories), dep)])])
    error_message = "depends_on can only reference valid keys within the repositories variable."
  }
}

variable "docker_host" {
  type    = string
  default = "unix:///var/run/docker.sock"
}