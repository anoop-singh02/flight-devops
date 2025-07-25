resource "aws_iam_role" "poller_role" {
  name = "flight_poller_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "poller_policy" {
  name = "flight_poller_permissions"
  role = aws_iam_role.poller_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["dynamodb:PutItem"], Resource = aws_dynamodb_table.flight_status.arn },
      { Effect = "Allow", Action = ["logs:*"], Resource = "arn:aws:logs:*:*:*" }
    ]
  })
}

data "archive_file" "poller_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/poller"
  output_path = "${path.module}/poller.zip"
}

resource "aws_lambda_function" "poller" {
  function_name = "flight_status_poller"
  role          = aws_iam_role.poller_role.arn
  runtime       = "python3.11"
  handler       = "handler.handler"

  filename         = data.archive_file.poller_zip.output_path
  source_code_hash = data.archive_file.poller_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.flight_status.name
    }
  }
}
