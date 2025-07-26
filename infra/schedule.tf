########################################
#  EventBridge rule: every 5 minutes
########################################
resource "aws_cloudwatch_event_rule" "five_min" {
  name                = "flight_status_poller_5min"
  description         = "Invoke poller Lambda every 5 minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "poller" {
  rule      = aws_cloudwatch_event_rule.five_min.name
  target_id = "invoke_poller"
  arn       = aws_lambda_function.poller.arn
}

########################################
#  Allow EventBridge to invoke Lambda
########################################
resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.poller.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.five_min.arn
}
