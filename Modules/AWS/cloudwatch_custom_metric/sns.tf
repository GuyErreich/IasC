resource "aws_sns_topic" "custom_cloudwatch_topic" {
  name = "${var.cloudwatch_alarm.name}_topic"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.custom_cloudwatch_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_handler.arn
}