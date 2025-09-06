terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# SNS 알림 토픽들
resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-critical-alerts"
}

resource "aws_sns_topic" "warning_alerts" {
  name = "${var.project_name}-warning-alerts"
}

resource "aws_sns_topic" "info_alerts" {
  name = "${var.project_name}-info-alerts"
}

# 이메일 구독
resource "aws_sns_topic_subscription" "critical_email" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.critical_alert_email
}

resource "aws_sns_topic_subscription" "warning_email" {
  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "email"
  endpoint  = var.warning_alert_email
}

# 고급 CloudWatch 알람들
resource "aws_cloudwatch_metric_alarm" "api_error_rate_critical" {
  alarm_name          = "${var.project_name}-api-error-rate-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "Critical: API error rate is too high"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.info_alerts.arn]

  dimensions = {
    LoadBalancer = data.aws_lb.main.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "response_time_critical" {
  alarm_name          = "${var.project_name}-response-time-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2.0"
  alarm_description   = "Critical: Response time is too high"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    LoadBalancer = data.aws_lb.main.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Warning: ECS CPU utilization is high"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    ServiceName = data.aws_ecs_service.main.service_name
    ClusterName = data.aws_ecs_cluster.main.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Warning: ECS memory utilization is high"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    ServiceName = data.aws_ecs_service.main.service_name
    ClusterName = data.aws_ecs_cluster.main.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Critical: DynamoDB throttling detected"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    TableName = "LiveInsight-Events"
  }
}

# 비즈니스 메트릭 알람
resource "aws_cloudwatch_metric_alarm" "low_event_volume" {
  alarm_name          = "${var.project_name}-low-event-volume"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "EventsProcessed"
  namespace           = "LiveInsight"
  period              = "900"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Warning: Event processing volume is unusually low"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]
  treat_missing_data  = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Critical: Lambda function errors detected"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    FunctionName = "LiveInsight-EventCollector"
  }
}

# 종합 운영 대시보드
resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "${var.project_name}-Operations"

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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", data.aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Application Load Balancer Metrics"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
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
            ["AWS/ECS", "CPUUtilization", "ServiceName", data.aws_ecs_service.main.service_name, "ClusterName", data.aws_ecs_cluster.main.cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            [".", "RunningTaskCount", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "LiveInsight-Events"],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "SuccessfulRequestLatency", ".", ".", "Operation", "PutItem"],
            [".", ".", ".", ".", ".", "Query"]
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
        x      = 8
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "LiveInsight-EventCollector"],
            [".", "Errors", ".", "."],
            [".", "Throttles", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Function Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["LiveInsight", "EventsProcessed"],
            [".", "ProcessingTime"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Business Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/lambda/LiveInsight-EventCollector' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Errors"
          view    = "table"
        }
      }
    ]
  })
}

# 데이터 소스들
data "aws_lb" "main" {
  name = "${var.project_name}-alb"
}

data "aws_ecs_cluster" "main" {
  cluster_name = "${var.project_name}-cluster"
}

data "aws_ecs_service" "main" {
  service_name = "${var.project_name}-service"
  cluster_arn  = data.aws_ecs_cluster.main.arn
}

# 자동 스케일링 정책 (고급)
resource "aws_appautoscaling_policy" "ecs_scale_up" {
  name               = "${var.project_name}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "service/${data.aws_ecs_cluster.main.cluster_name}/${data.aws_ecs_service.main.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# 로그 집계 및 분석
resource "aws_cloudwatch_log_group" "aggregated_logs" {
  name              = "/aws/liveinsight/aggregated"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "error_stream" {
  name           = "errors"
  log_group_name = aws_cloudwatch_log_group.aggregated_logs.name
}

resource "aws_cloudwatch_log_stream" "performance_stream" {
  name           = "performance"
  log_group_name = aws_cloudwatch_log_group.aggregated_logs.name
}

# 로그 메트릭 필터 (고급)
resource "aws_cloudwatch_log_metric_filter" "error_rate" {
  name           = "${var.project_name}-error-rate"
  log_group_name = "/aws/lambda/LiveInsight-EventCollector"
  pattern        = "[timestamp, request_id, \"ERROR\", ...]"

  metric_transformation {
    name      = "ErrorRate"
    namespace = "LiveInsight/Errors"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "slow_requests" {
  name           = "${var.project_name}-slow-requests"
  log_group_name = "/ecs/liveinsight"
  pattern        = "[timestamp, level=\"INFO\", message=\"Request processed\", duration > 1000]"

  metric_transformation {
    name      = "SlowRequests"
    namespace = "LiveInsight/Performance"
    value     = "$duration"
  }
}