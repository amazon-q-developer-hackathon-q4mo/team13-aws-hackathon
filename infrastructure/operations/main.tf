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

# 운영 자동화 Lambda 함수들
resource "aws_lambda_function" "auto_scaling" {
  filename         = "auto_scaling.zip"
  function_name    = "${var.project_name}-auto-scaling"
  role            = aws_iam_role.operations_lambda.arn
  handler         = "auto_scaling.handler"
  runtime         = "python3.11"
  timeout         = 300

  environment {
    variables = {
      CLUSTER_NAME = "${var.project_name}-cluster"
      SERVICE_NAME = "${var.project_name}-service"
      PROJECT_NAME = var.project_name
    }
  }
}

resource "aws_lambda_function" "log_cleanup" {
  filename         = "log_cleanup.zip"
  function_name    = "${var.project_name}-log-cleanup"
  role            = aws_iam_role.operations_lambda.arn
  handler         = "log_cleanup.handler"
  runtime         = "python3.11"
  timeout         = 900

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      RETENTION_DAYS = "30"
    }
  }
}

resource "aws_lambda_function" "health_monitor" {
  filename         = "health_monitor.zip"
  function_name    = "${var.project_name}-health-monitor"
  role            = aws_iam_role.operations_lambda.arn
  handler         = "health_monitor.handler"
  runtime         = "python3.11"
  timeout         = 300

  environment {
    variables = {
      DOMAIN_NAME = var.domain_name
      PROJECT_NAME = var.project_name
      SNS_TOPIC_ARN = data.aws_sns_topic.critical_alerts.arn
    }
  }
}

resource "aws_lambda_function" "cost_optimizer" {
  filename         = "cost_optimizer.zip"
  function_name    = "${var.project_name}-cost-optimizer"
  role            = aws_iam_role.operations_lambda.arn
  handler         = "cost_optimizer.handler"
  runtime         = "python3.11"
  timeout         = 600

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      COST_THRESHOLD = "150" # $150/월
    }
  }
}

# 운영 Lambda IAM 역할
resource "aws_iam_role" "operations_lambda" {
  name = "${var.project_name}-operations-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "operations_lambda" {
  name = "${var.project_name}-operations-lambda-policy"
  role = aws_iam_role.operations_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DeleteLogGroup",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeClusters",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:PutMetricData",
          "sns:Publish",
          "ce:GetCostAndUsage",
          "ce:GetUsageReport",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable"
        ]
        Resource = "*"
      }
    ]
  })
}

# 스케줄링된 작업들
resource "aws_cloudwatch_event_rule" "auto_scaling_check" {
  name                = "${var.project_name}-auto-scaling-check"
  description         = "Check and adjust ECS service scaling"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "auto_scaling_check" {
  rule      = aws_cloudwatch_event_rule.auto_scaling_check.name
  target_id = "AutoScalingTarget"
  arn       = aws_lambda_function.auto_scaling.arn
}

resource "aws_lambda_permission" "auto_scaling_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_scaling.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.auto_scaling_check.arn
}

resource "aws_cloudwatch_event_rule" "log_cleanup" {
  name                = "${var.project_name}-log-cleanup"
  description         = "Clean up old logs"
  schedule_expression = "cron(0 2 * * ? *)" # 매일 오전 2시
}

resource "aws_cloudwatch_event_target" "log_cleanup" {
  rule      = aws_cloudwatch_event_rule.log_cleanup.name
  target_id = "LogCleanupTarget"
  arn       = aws_lambda_function.log_cleanup.arn
}

resource "aws_lambda_permission" "log_cleanup" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.log_cleanup.arn
}

resource "aws_cloudwatch_event_rule" "health_monitor" {
  name                = "${var.project_name}-health-monitor"
  description         = "Monitor application health"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "health_monitor" {
  rule      = aws_cloudwatch_event_rule.health_monitor.name
  target_id = "HealthMonitorTarget"
  arn       = aws_lambda_function.health_monitor.arn
}

resource "aws_lambda_permission" "health_monitor" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_monitor.arn
}

resource "aws_cloudwatch_event_rule" "cost_optimizer" {
  name                = "${var.project_name}-cost-optimizer"
  description         = "Optimize costs"
  schedule_expression = "cron(0 8 * * ? *)" # 매일 오전 8시
}

resource "aws_cloudwatch_event_target" "cost_optimizer" {
  rule      = aws_cloudwatch_event_rule.cost_optimizer.name
  target_id = "CostOptimizerTarget"
  arn       = aws_lambda_function.cost_optimizer.arn
}

resource "aws_lambda_permission" "cost_optimizer" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_optimizer.arn
}

# 데이터 소스
data "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-critical-alerts"
}

# 운영 대시보드 (자동화 상태)
resource "aws_cloudwatch_dashboard" "automation" {
  dashboard_name = "${var.project_name}-Automation"

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
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.auto_scaling.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Auto Scaling Lambda Metrics"
          period  = 300
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
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.health_monitor.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Health Monitor Lambda Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["LiveInsight/Operations", "AutoScalingActions"],
            [".", "HealthCheckFailures"],
            [".", "CostOptimizations"],
            [".", "LogCleanupActions"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Automation Actions"
          period  = 300
        }
      }
    ]
  })
}

# 자동화 상태 추적을 위한 DynamoDB 테이블
resource "aws_dynamodb_table" "automation_state" {
  name           = "${var.project_name}-automation-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "automation_type"
  range_key      = "timestamp"

  attribute {
    name = "automation_type"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-automation-state"
  }
}