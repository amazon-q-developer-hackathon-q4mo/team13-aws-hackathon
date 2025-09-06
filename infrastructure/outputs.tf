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

# Django 웹 애플리케이션 출력
output "web_app_url" {
  description = "Django web application URL"
  value       = "http://${module.web_app.alb_dns_name}"
}

output "web_app_dashboard_url" {
  description = "Django dashboard URL"
  value       = "http://${module.web_app.alb_dns_name}/"
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.web_app.dashboard_name}"
}

# S3 버킷 출력
output "static_files_bucket" {
  description = "S3 bucket for static files"
  value       = aws_s3_bucket.static_files.bucket
}

output "static_files_bucket_url" {
  description = "S3 bucket URL for static files"
  value       = "https://${aws_s3_bucket.static_files.bucket}.s3.${var.aws_region}.amazonaws.com"
}

output "alb_logs_bucket" {
  description = "S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "backups_bucket" {
  description = "S3 bucket for backups"
  value       = aws_s3_bucket.backups.bucket
}