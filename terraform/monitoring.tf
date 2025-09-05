# CloudWatch 로그 그룹 - Event Collector
resource "aws_cloudwatch_log_group" "event_collector" {
  name              = "/aws/lambda/${local.event_collector.function_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-event-collector-logs"
  }
}

# CloudWatch 로그 그룹 - Realtime API
resource "aws_cloudwatch_log_group" "realtime_api" {
  name              = "/aws/lambda/${local.realtime_api.function_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-realtime-api-logs"
  }
}

# CloudWatch 로그 그룹 - Stats API
resource "aws_cloudwatch_log_group" "stats_api" {
  name              = "/aws/lambda/${local.stats_api.function_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-stats-api-logs"
  }
}

# CloudWatch 로그 그룹 - API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.liveinsight_api.id}/${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-api-gateway-logs"
  }
}

# Lambda 에러 알람 - Event Collector
resource "aws_cloudwatch_metric_alarm" "event_collector_errors" {
  alarm_name          = "${var.project_name}-event-collector-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Event Collector Lambda function errors"
  alarm_actions       = []

  dimensions = {
    FunctionName = local.event_collector.function_name
  }

  tags = {
    Name = "${var.project_name}-event-collector-errors"
  }
}

# Lambda 에러 알람 - Realtime API
resource "aws_cloudwatch_metric_alarm" "realtime_api_errors" {
  alarm_name          = "${var.project_name}-realtime-api-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Realtime API Lambda function errors"
  alarm_actions       = []

  dimensions = {
    FunctionName = local.realtime_api.function_name
  }

  tags = {
    Name = "${var.project_name}-realtime-api-errors"
  }
}

# Lambda 에러 알람 - Stats API
resource "aws_cloudwatch_metric_alarm" "stats_api_errors" {
  alarm_name          = "${var.project_name}-stats-api-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Stats API Lambda function errors"
  alarm_actions       = []

  dimensions = {
    FunctionName = local.stats_api.function_name
  }

  tags = {
    Name = "${var.project_name}-stats-api-errors"
  }
}

# Lambda Duration 알람 - Event Collector
resource "aws_cloudwatch_metric_alarm" "event_collector_duration" {
  alarm_name          = "${var.project_name}-event-collector-duration-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "25000"  # 25초
  alarm_description   = "Event Collector Lambda function duration"
  alarm_actions       = []

  dimensions = {
    FunctionName = local.event_collector.function_name
  }

  tags = {
    Name = "${var.project_name}-event-collector-duration"
  }
}

# API Gateway 4XX 에러 알람
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  alarm_name          = "${var.project_name}-api-gateway-4xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "API Gateway 4XX errors"
  alarm_actions       = []

  dimensions = {
    ApiName = aws_api_gateway_rest_api.liveinsight_api.name
    Stage   = var.environment
  }

  tags = {
    Name = "${var.project_name}-api-gateway-4xx-errors"
  }
}

# API Gateway 5XX 에러 알람
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${var.project_name}-api-gateway-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "API Gateway 5XX errors"
  alarm_actions       = []

  dimensions = {
    ApiName = aws_api_gateway_rest_api.liveinsight_api.name
    Stage   = var.environment
  }

  tags = {
    Name = "${var.project_name}-api-gateway-5xx-errors"
  }
}

# DynamoDB 읽기 스로틀 알람 - Events 테이블
resource "aws_cloudwatch_metric_alarm" "dynamodb_events_read_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-events-read-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DynamoDB Events table read throttles"
  alarm_actions       = []

  dimensions = {
    TableName = aws_dynamodb_table.events.name
  }

  tags = {
    Name = "${var.project_name}-dynamodb-events-read-throttles"
  }
}

# DynamoDB 쓰기 스로틀 알람 - Events 테이블
resource "aws_cloudwatch_metric_alarm" "dynamodb_events_write_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-events-write-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DynamoDB Events table write throttles"
  alarm_actions       = []

  dimensions = {
    TableName = aws_dynamodb_table.events.name
  }

  tags = {
    Name = "${var.project_name}-dynamodb-events-write-throttles"
  }
}