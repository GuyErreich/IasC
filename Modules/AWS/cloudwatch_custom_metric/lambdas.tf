resource "aws_lambda_function" "alarm_handler" {
  depends_on = [aws_iam_role.lambda_exec]

  # Force update when the zip_files resource changes
  source_code_hash = filebase64sha256(var.lambda_alarm_handler.filename)

  filename      = var.lambda_alarm_handler.filename
  function_name = var.lambda_alarm_handler.name
  role          = aws_iam_role.lambda_exec["lambda_alarm_handler_exec_role_name"].arn
  handler       = var.lambda_alarm_handler.handler
  runtime       = var.lambda_alarm_handler.runtime

  environment {
    variables = var.lambda_alarm_handler.environment_vars
  }

  logging_config {
    log_group = "/aws/lambda/${var.lambda_alarm_handler.name}"
    # application_log_level = 
    log_format = "Text"
    # system_log_level = 
  }
}

resource "aws_lambda_function" "metric_generator" {
  depends_on = [aws_iam_role.lambda_exec]

  # Force update when the zip_files resource changes
  source_code_hash = filebase64sha256(var.lambda_metric_generator.filename)

  filename      = var.lambda_metric_generator.filename
  function_name = var.lambda_metric_generator.name
  role          = aws_iam_role.lambda_exec["lambda_metric_generator_exec_role_name"].arn
  handler       = var.lambda_metric_generator.handler
  runtime       = var.lambda_metric_generator.runtime

  environment {
    variables = var.lambda_metric_generator.environment_vars
  }

  logging_config {
    log_group = "/aws/lambda/${var.lambda_metric_generator.name}"
    # application_log_level = 
    log_format = "Text"
    # system_log_level = 
  }
}
