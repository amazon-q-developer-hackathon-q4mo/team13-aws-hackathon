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
  value       = local.event_collector.function_name
}

output "lambda_realtime_api_name" {
  description = "Realtime API Lambda function name"
  value       = local.realtime_api.function_name
}

output "lambda_stats_api_name" {
  description = "Stats API Lambda function name"
  value       = local.stats_api.function_name
}

# API Gateway
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.liveinsight_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}"
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.liveinsight_api.id
}

# S3 및 CloudFront
output "s3_bucket_name" {
  description = "S3 bucket name for static files"
  value       = aws_s3_bucket.static_files.bucket
}

output "s3_website_url" {
  description = "S3 website URL"
  value       = "http://${aws_s3_bucket.static_files.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.static_files.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.static_files.id
}

# Team collaboration information
output "deployment_info" {
  description = "Deployment information for team collaboration"
  value = {
    api_base_url    = "https://${aws_api_gateway_rest_api.liveinsight_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}"
    dashboard_url   = "https://${aws_cloudfront_distribution.static_files.domain_name}"
    events_table    = aws_dynamodb_table.events.name
    sessions_table  = aws_dynamodb_table.sessions.name
    lambda_functions = {
      event_collector = local.event_collector.function_name
      realtime_api    = local.realtime_api.function_name
      stats_api       = local.stats_api.function_name
    }
  }
}