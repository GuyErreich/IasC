resource "aws_iam_role_policy" "lambda_put_metric" {
  for_each = aws_iam_role.lambda_exec

  name = "LambdaPutMetric"
  role = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}