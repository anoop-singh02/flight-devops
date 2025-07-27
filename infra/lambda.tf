resource "aws_iam_role_policy" "poller_policy" {
  name = "flight_poller_permissions"
  role = aws_iam_role.poller_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # write rows in DynamoDB
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.flight_status.arn
      },
      # create / write to CloudWatch Logs
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
