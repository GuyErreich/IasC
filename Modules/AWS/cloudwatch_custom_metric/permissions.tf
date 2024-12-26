resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  depends_on = [ 
    aws_lambda_function.metric_generator,
    aws_cloudwatch_event_rule.event_rule
  ]

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metric_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
}

resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  depends_on = [ 
    aws_lambda_function.alarm_handler,
    aws_sns_topic.custom_cloudwatch_topic
  ]

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.custom_cloudwatch_topic.arn
}