########################################
#  Package code
########################################
data "archive_file" "api_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/api"
  output_path = "${path.module}/api.zip"
}

########################################
#  IAM trust policy for all Lambdas
########################################
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

########################################
#  IAM for reader Lambda
########################################
resource "aws_iam_role" "api_role" {
  name               = "flight_api_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy" "api_policy" {
  name = "flight_api_permissions"
  role = aws_iam_role.api_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan"]
        Resource = aws_dynamodb_table.flight_status.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

########################################
#  Reader Lambda
########################################
resource "aws_lambda_function" "api" {
  function_name = "flight_status_api"
  role          = aws_iam_role.api_role.arn
  runtime       = "python3.11"
  handler       = "handler.handler"

  filename         = data.archive_file.api_zip.output_path
  source_code_hash = data.archive_file.api_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.flight_status.name
    }
  }
}

########################################
#  HTTP API Gateway v2  (+ CORS)
########################################
resource "aws_apigatewayv2_api" "http" {
  name          = "flight_http_api"
  protocol_type = "HTTP"

  # --- CORS so the static site can fetch the API ----------------------------
  cors_configuration {
    allow_origins = ["*"]       # replace with your S3 website URL to lock down
    allow_methods = ["GET"]
    allow_headers = ["*"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# root route, any method → Lambda
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# auto‑deploy (single default stage, no custom domain)
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

# allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

########################################
#  Outputs
########################################
output "api_base_url" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}
