########################################
#  Alerts – SNS + subscription Lambda
########################################

# DynamoDB table to keep who‑subscribed‑to‑what
resource "aws_dynamodb_table" "subscriptions" {
  name         = "flight_subscriptions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "FlightId"
  range_key    = "Email"

  attribute {
    name = "FlightId"
    type = "S"
  }
  attribute {
    name = "Email"
    type = "S"
  }
}

# SNS topic – every status‑change message is published here
resource "aws_sns_topic" "alerts" {
  name = "flight_status_alerts"
}

# ───── Subscription Lambda ────────────────────────────────
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
    Statement = [
      { Effect = "Allow", Action = ["dynamodb:PutItem"], Resource = aws_dynamodb_table.subscriptions.arn },
      { Effect = "Allow", Action = ["sns:Subscribe"], Resource = aws_sns_topic.alerts.arn }
    ]
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
      TABLE_NAME   = aws_dynamodb_table.subscriptions.name
      TOPIC_ARN    = aws_sns_topic.alerts.arn
      ALLOWED_ORIG = "*" # CORS pre‑flight handled below
    }
  }
}

# ───── expose /subscribe endpoint (POST) ───────────────────
resource "aws_apigatewayv2_integration" "subscribe_lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.subscribe.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "subscribe_route" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /subscribe"
  target    = "integrations/${aws_apigatewayv2_integration.subscribe_lambda.id}"
}

resource "aws_lambda_permission" "allow_apigw_subscribe" {
  statement_id  = "AllowAPIGatewayInvokeSubscribe"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.subscribe.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

########################################
#  Outputs
########################################
output "frontend_bucket_url" {
  value = "http://${var.frontend_bucket}.s3-website-${var.aws_region}.amazonaws.com"
}
