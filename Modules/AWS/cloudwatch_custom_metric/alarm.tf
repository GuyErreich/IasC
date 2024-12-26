resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name          = var.cloudwatch_alarm.name
  comparison_operator = var.cloudwatch_alarm.comparison_operator
  evaluation_periods  = var.cloudwatch_alarm.evaluation_periods
  metric_name         = var.cloudwatch_alarm.metric_name
  namespace           = var.cloudwatch_alarm.namespace
  period              = var.cloudwatch_alarm.period
  statistic           = var.cloudwatch_alarm.statistic
  threshold           = var.cloudwatch_alarm.threshold
  dimensions          = var.cloudwatch_alarm.dimensions

  alarm_actions = [aws_sns_topic.custom_cloudwatch_topic.arn]
}

