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

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# DynamoDB 글로벌 테이블 (재해복구용)
resource "aws_dynamodb_table" "events_dr" {
  provider = aws.dr
  
  name           = "LiveInsight-Events-DR"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "event_id"
  range_key      = "timestamp"
  stream_enabled = true

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name     = "UserIndex"
    hash_key = "user_id"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "LiveInsight-Events-DR"
    Environment = "disaster-recovery"
  }
}

# DynamoDB 글로벌 테이블 복제 설정
resource "aws_dynamodb_global_table" "events" {
  depends_on = [
    aws_dynamodb_table.events_dr
  ]

  name = "LiveInsight-Events"

  replica {
    region_name = var.aws_region
  }

  replica {
    region_name = var.dr_region
  }
}

# Route 53 헬스체크 기반 장애조치
data "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_health_check" "primary" {
  fqdn                            = var.domain_name
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health/"
  failure_threshold               = 3
  request_interval                = 30
  cloudwatch_logs_region          = var.aws_region
  cloudwatch_alarm_region         = var.aws_region
  insufficient_data_health_status = "Failure"

  tags = {
    Name = "${var.project_name}-primary-health"
  }
}

resource "aws_route53_health_check" "secondary" {
  fqdn                            = "${var.dr_region}.${var.domain_name}"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health/"
  failure_threshold               = 3
  request_interval                = 30
  cloudwatch_logs_region          = var.dr_region
  cloudwatch_alarm_region         = var.dr_region
  insufficient_data_health_status = "Failure"

  tags = {
    Name = "${var.project_name}-secondary-health"
  }
}

# 장애조치 라우팅 정책
resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = data.aws_lb.primary.dns_name
    zone_id                = data.aws_lb.primary.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "secondary"
  
  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = aws_route53_health_check.secondary.id

  alias {
    name                   = aws_lb.dr.dns_name
    zone_id                = aws_lb.dr.zone_id
    evaluate_target_health = true
  }
}

data "aws_lb" "primary" {
  name = "${var.project_name}-alb"
}

# DR 리전 ALB (간소화된 구성)
resource "aws_lb" "dr" {
  provider = aws.dr
  
  name               = "${var.project_name}-alb-dr"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_dr.id]
  subnets           = data.aws_subnets.dr.ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb-dr"
    Environment = "disaster-recovery"
  }
}

data "aws_vpc" "dr" {
  provider = aws.dr
  default  = true
}

data "aws_subnets" "dr" {
  provider = aws.dr
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dr.id]
  }
}

resource "aws_security_group" "alb_dr" {
  provider = aws.dr
  
  name_prefix = "${var.project_name}-alb-dr-"
  vpc_id      = data.aws_vpc.dr.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-dr-sg"
  }
}

# DR 자동화 Lambda
resource "aws_lambda_function" "dr_automation" {
  filename         = "dr_automation.zip"
  function_name    = "${var.project_name}-dr-automation"
  role            = aws_iam_role.dr_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 900

  environment {
    variables = {
      PRIMARY_REGION = var.aws_region
      DR_REGION      = var.dr_region
      PROJECT_NAME   = var.project_name
      DOMAIN_NAME    = var.domain_name
    }
  }
}

resource "aws_iam_role" "dr_lambda" {
  name = "${var.project_name}-dr-lambda-role"

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

resource "aws_iam_role_policy" "dr_lambda" {
  name = "${var.project_name}-dr-lambda-policy"
  role = aws_iam_role.dr_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "route53:ChangeResourceRecordSets",
          "route53:GetHealthCheck",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "dynamodb:DescribeTable",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

# DR 테스트 스케줄
resource "aws_cloudwatch_event_rule" "dr_test" {
  name                = "${var.project_name}-dr-test"
  description         = "Monthly DR test"
  schedule_expression = "cron(0 6 15 * ? *)" # 매월 15일 오전 6시
}

resource "aws_cloudwatch_event_target" "dr_test" {
  rule      = aws_cloudwatch_event_rule.dr_test.name
  target_id = "DRTestTarget"
  arn       = aws_lambda_function.dr_automation.arn

  input = jsonencode({
    action = "test"
  })
}

resource "aws_lambda_permission" "dr_test" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_automation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_test.arn
}

# SNS 알림 토픽
resource "aws_sns_topic" "dr_alerts" {
  name = "${var.project_name}-dr-alerts"
}

resource "aws_sns_topic_subscription" "dr_email" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch 알람 (DR 상태 모니터링)
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  alarm_name          = "${var.project_name}-primary-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Primary region is unhealthy"
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }
}

resource "aws_cloudwatch_metric_alarm" "dr_activated" {
  alarm_name          = "${var.project_name}-dr-activated"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "DR region is now active"
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.secondary.id
  }
}