output "events_table_name" {
  description = "Name of the Events DynamoDB table"
  value       = aws_dynamodb_table.events.name
}

output "events_table_arn" {
  description = "ARN of the Events DynamoDB table"
  value       = aws_dynamodb_table.events.arn
}

output "sessions_table_name" {
  description = "Name of the Sessions DynamoDB table"
  value       = aws_dynamodb_table.sessions.name
}

output "sessions_table_arn" {
  description = "ARN of the Sessions DynamoDB table"
  value       = aws_dynamodb_table.sessions.arn
}

output "active_sessions_table_name" {
  description = "Name of the ActiveSessions DynamoDB table"
  value       = aws_dynamodb_table.active_sessions.name
}

output "active_sessions_table_arn" {
  description = "ARN of the ActiveSessions DynamoDB table"
  value       = aws_dynamodb_table.active_sessions.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.event_collector.function_name
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/prod"
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.main.id
}