//TODO: better description
variable "event_rule" {
    description = "The name for the lambda function"
    type = object({
      name          = string
      description   = string
      event_pattern = string
    })
}

//TODO: better description
variable "cloudwatch_alarm" {
    description = "The name for the lambda function"
    type = object({
      name                = string
      comparison_operator = string
      evaluation_periods  = string
      metric_name         = string
      namespace           = string
      period              = string
      statistic           = string
      threshold           = string
      dimensions          = map(string)
    })
}

//TODO: better description
variable "lambda_alarm_handler" {
    description = "The name for the lambda function"
    type = object({
      name              = string
      filename          = string
      handler           = string
      runtime           = optional(string, "python3.9")
      environment_vars  = map(string)
    })
}

//TODO: better description
variable "lambda_metric_generator" {
    description = "The name for the lambda function"
    type = object({
      name              = string
      filename          = string
      handler           = string
      runtime           = optional(string, "python3.9")
      environment_vars  = map(string)
    })
}