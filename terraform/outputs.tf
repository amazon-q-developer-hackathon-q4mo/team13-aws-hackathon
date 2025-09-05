output "events_table_name" {
  description = "DynamoDB Events table name"
  value       = aws_dynamodb_table.events.name
}

output "sessions_table_name" {
  description = "DynamoDB Sessions table name"
  value       = aws_dynamodb_table.sessions.name
}

output "lambda_event_collector_name" {
  description = "Event Collector Lambda function name"
  value       = aws_lambda_function.event_collector.function_name
}

output "lambda_realtime_api_name" {
  description = "Realtime API Lambda function name"
  value       = aws_lambda_function.realtime_api.function_name
}

output "lambda_stats_api_name" {
  description = "Stats API Lambda function name"
  value       = aws_lambda_function.stats_api.function_name
}