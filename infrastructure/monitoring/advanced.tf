# 고급 모니터링 및 알람 설정

# 커스텀 메트릭을 위한 CloudWatch 로그 그룹
resource "aws_cloudwatch_log_group" "custom_metrics" {
  name              = "/aws/lambda/liveinsight-custom-metrics"
  retention_in_days = 14

  tags = {
    Name = "LiveInsight-CustomMetrics"
  }
}

# X-Ray 트레이싱 설정
resource "aws_xray_sampling_rule" "liveinsight_sampling" {
  rule_name      = "LiveInsightSampling"
  priority       = 9000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_name   = "liveinsight"
  service_type   = "*"
  resource_arn   = "*"
}

# 고급 CloudWatch 알람
resource "aws_cloudwatch_metric_alarm" "api_error_rate" {
  alarm_name          = "LiveInsight-API-ErrorRate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "API error rate is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "LiveInsight-API-ErrorRate"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "LiveInsight-Lambda-Duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5초
  alarm_description   = "Lambda function duration is too high"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name = "LiveInsight-Lambda-Duration"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "LiveInsight-Lambda-Throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Lambda function is being throttled"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name = "LiveInsight-Lambda-Throttles"
  }
}

# 커스텀 메트릭 필터
resource "aws_cloudwatch_log_metric_filter" "events_processed" {
  name           = "EventsProcessed"
  log_group_name = var.lambda_log_group_name
  pattern        = "[timestamp, request_id, EVENT_PROCESSED, ...]"

  metric_transformation {
    name      = "EventsProcessed"
    namespace = "LiveInsight/Lambda"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "processing_time" {
  name           = "ProcessingTime"
  log_group_name = var.lambda_log_group_name
  pattern        = "[timestamp, request_id, PROCESSING_TIME, duration]"

  metric_transformation {
    name      = "ProcessingTime"
    namespace = "LiveInsight/Lambda"
    value     = "$duration"
  }
}

# 비즈니스 메트릭 대시보드
resource "aws_cloudwatch_dashboard" "business_metrics" {
  dashboard_name = "LiveInsight-BusinessMetrics"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["LiveInsight/Lambda", "EventsProcessed"],
            [".", "ProcessingTime"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Event Processing Metrics"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", var.events_table_name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "SuccessfulRequestLatency", ".", ".", "Operation", "Query"],
            [".", ".", ".", ".", ".", "PutItem"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DynamoDB Performance"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.ecs_service_name, "ClusterName", var.ecs_cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      }
    ]
  })
}

# 성능 임계값 기반 알람
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "LiveInsight-HighResponseTime"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.5"  # 500ms
  alarm_description   = "Application response time is too high"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "LiveInsight-HighResponseTime"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_event_processing" {
  alarm_name          = "LiveInsight-LowEventProcessing"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EventsProcessed"
  namespace           = "LiveInsight/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Event processing rate is too low"
  treat_missing_data  = "breaching"

  tags = {
    Name = "LiveInsight-LowEventProcessing"
  }
}

# 장애 예측 알람
resource "aws_cloudwatch_metric_alarm" "predictive_scaling" {
  alarm_name          = "LiveInsight-PredictiveScaling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"  # 5분간 1000 요청
  alarm_description   = "High traffic detected - consider scaling"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "LiveInsight-PredictiveScaling"
  }
}