variable "lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
  default     = "github-secrets-rotation"
}

variable "github_owner" {
  description = "GitHub organization or user"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token (PAT)"
  type        = string
  sensitive   = true
}

variable "secrets" {
  description = "A map of secret names, GitHub secret names, and rotation intervals"
  type = map(object({
    github_secret_name = string
    rotation_days      = number
    github_permissions = map(string)
  }))
}
