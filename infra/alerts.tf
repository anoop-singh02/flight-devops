resource "aws_sns_topic" "alerts" {
  name = "flight_status_alerts"
}

data "archive_file" "subscribe_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/subscribe"
  output_path = "${path.module}/subscribe.zip"
}

resource "aws_iam_role" "subscribe_role" {
  name               = "flight_subscribe_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy" "subscribe_policy" {
  name = "flight_subscribe_permissions"
  role = aws_iam_role.subscribe_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sns:Subscribe"],
      Resource = aws_sns_topic.alerts.arn
    }]
  })
}

resource "aws_lambda_function" "subscribe" {
  function_name    = "flight_status_subscribe"
  role             = aws_iam_role.subscribe_role.arn
  runtime          = "python3.11"
  handler          = "handler.handler"
  filename         = data.archive_file.subscribe_zip.output_path
  source_code_hash = data.archive_file.subscribe_zip.output_base64sha256
  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}
