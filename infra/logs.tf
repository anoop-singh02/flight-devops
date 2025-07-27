resource "aws_cloudwatch_log_group" "poller" {
  name              = "/aws/lambda/${aws_lambda_function.poller.function_name}"
  retention_in_days = 14
}
