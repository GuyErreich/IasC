output "lambda_alarm_handler_exec_role" {
  depends_on = [aws_iam_role.lambda_exec["lambda_alarm_handler_exec_role_name"]]
  value      = aws_iam_role.lambda_exec["lambda_alarm_handler_exec_role_name"]
}

output "lambda_metric_generator_exec_role" {
  depends_on = [aws_iam_role.lambda_exec["lambda_metric_generator_exec_role_name"]]
  value      = aws_iam_role.lambda_exec["lambda_metric_generator_exec_role_name"]
}