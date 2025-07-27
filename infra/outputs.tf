output "lambda_poller_arn" {
  value = aws_lambda_function.poller.arn
}

output "flight_status_table" {
  value = aws_dynamodb_table.flight_status.name
}
