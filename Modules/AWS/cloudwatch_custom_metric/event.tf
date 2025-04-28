resource "aws_cloudwatch_event_rule" "event_rule" {
  name          = var.event_rule.name
  description   = var.event_rule.description
  event_pattern = var.event_rule.event_pattern
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = aws_lambda_function.metric_generator.function_name
  arn       = aws_lambda_function.metric_generator.arn
}
