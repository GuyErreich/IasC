locals {
  environment_vars = {
    CLUSTER_NAME = module.ecs.cluster_name
    SERVICE_NAME = module.ecs.services["unreal_engine"].name // TODO: in the future might want this more dynamic with a loop over all services
  }
}

module "ecs_task_failure_handler" {
  source = "../../Modules/AWS/cloudwatch_custom_metric"

  event_rule = {
    name        = "ecs_task_stop"
    description = "Trigger when ECS tasks stop"

    event_pattern = jsonencode({
      "detail-type" : ["ECS Task State Change"],
      "source" : ["aws.ecs"],
      "detail" : {
        "lastStatus" : ["STOPPED"],
        "stopCode" : ["EssentialContainerExited"]
      }
    })
  }

  lambda_metric_generator = {
    name             = "task_failure_metric_generator"
    filename         = var.lambda_zip
    handler          = "cloudwatch.generate_metrics_for_failure_alarm"
    environment_vars = local.environment_vars
  }

  cloudwatch_alarm = {
    name                = "ecs_task_failure_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = "EssentialContainerExited"
    namespace           = "ECS/TaskFailures"
    period              = 30 * 60
    statistic           = "Sum"
    threshold           = 2

    dimensions = {
      ClusterName = module.ecs.cluster_arn
      ServiceName = module.ecs.services["unreal_engine"].name
    }
  }

  lambda_alarm_handler = {
    name             = "task_failure_handler"
    filename         = var.lambda_zip
    handler          = "ecs.reset_desired_count_on_repeating_failure"
    environment_vars = local.environment_vars
  }

}

resource "aws_iam_role_policy" "lambda_ecs_update" {
  name = "LambdaECSUpdate"
  role = module.ecs_task_failure_handler.lambda_alarm_handler_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}