locals {
  push_command = <<EOT
      task -d %s push IMAGE_NAME=%s
                      TAG=%s
                      CONTEXT=%s
                      FILE=%s
                      REGION=${data.aws_region.current.name}
                      ACCOUNT_ID=${data.aws_caller_identity.current.account_id}
    EOT

  # repository_url = {
  #   for repo in module.ecr_repos : repo.repository_name => repo.repository_url
  # }
}