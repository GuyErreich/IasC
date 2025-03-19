variable "roles" {
  description = <<-EOT
  A list of objects defining IAM roles for GitHub OIDC and their configurations.
  Each object should contain:
  - `name` (string): The name of the IAM role.
  - `subjects` (list(string)): GitHub OIDC subjects permitted by the trust policy.
    Example: ['my-org/my-repo:*', 'octo-org/octo-repo:ref:refs/heads/octo-branch'].
  - `policies` (map): Key-value pairs where keys are the policy names, and values are the ARNs of the policies.
  EOT
  type = map(object({
    subjects = list(string)
    policies = map(string)
  }))

  validation {
    condition = !anytrue([
      for role_name in keys(var.roles) : role_name if role_name == "" && contains(data.aws_iam_roles.roles.names, role_name)
    ])
    error_message = "One or more IAM roles already exist in AWS. Please use a different role name."
  }
}

