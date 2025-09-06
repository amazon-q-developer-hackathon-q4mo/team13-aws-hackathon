terraform {
  required_version = ">= 1.0"
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

# DynamoDB Events 테이블
resource "aws_dynamodb_table" "events" {
  name           = "LiveInsight-Events"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "event_id"
  range_key      = "timestamp"

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

  attribute {
    name = "session_id"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "user_id"
    range_key       = "timestamp"
    read_capacity   = 5
    write_capacity  = 5
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "SessionIndex"
    hash_key        = "session_id"
    range_key       = "timestamp"
    read_capacity   = 5
    write_capacity  = 5
    projection_type = "ALL"
  }

  tags = {
    Name        = "LiveInsight-Events"
    Environment = "hackathon"
    Project     = "LiveInsight"
  }
}

# DynamoDB Sessions 테이블
resource "aws_dynamodb_table" "sessions" {
  name           = "LiveInsight-Sessions"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "start_time"
    type = "N"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "user_id"
    range_key       = "start_time"
    read_capacity   = 5
    write_capacity  = 5
    projection_type = "ALL"
  }

  tags = {
    Name        = "LiveInsight-Sessions"
    Environment = "hackathon"
    Project     = "LiveInsight"
  }
}

# DynamoDB ActiveSessions 테이블 (TTL 포함)
resource "aws_dynamodb_table" "active_sessions" {
  name           = "LiveInsight-ActiveSessions"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name        = "LiveInsight-ActiveSessions"
    Environment = "hackathon"
    Project     = "LiveInsight"
  }
}

# IAM 역할 (Lambda보다 먼저 생성)
resource "aws_iam_role" "lambda_role" {
  name = "LiveInsight-Lambda-Role"

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

  tags = {
    Name        = "LiveInsight-Lambda-Role"
    Environment = "hackathon"
    Project     = "LiveInsight"
  }
}

# Lambda 기본 실행 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB 접근 정책
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "LiveInsight-DynamoDB-Policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.events.arn,
          aws_dynamodb_table.sessions.arn,
          aws_dynamodb_table.active_sessions.arn,
          "${aws_dynamodb_table.events.arn}/index/*",
          "${aws_dynamodb_table.sessions.arn}/index/*"
        ]
      }
    ]
  })
}

# CloudWatch 메트릭 정책
resource "aws_iam_role_policy" "lambda_cloudwatch" {
  name = "LiveInsight-CloudWatch-Policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda 함수
resource "aws_lambda_function" "event_collector" {
  filename         = "lambda_function.zip"
  function_name    = "LiveInsight-EventCollector"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  memory_size     = 512
  timeout         = 30

  environment {
    variables = {
      EVENTS_TABLE          = aws_dynamodb_table.events.name
      SESSIONS_TABLE        = aws_dynamodb_table.sessions.name
      ACTIVE_SESSIONS_TABLE = aws_dynamodb_table.active_sessions.name
    }
  }

  tags = {
    Name        = "LiveInsight-EventCollector"
    Environment = "hackathon"
    Project     = "LiveInsight"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name = "LiveInsight-API"

  tags = {
    Name        = "LiveInsight-API"
    Environment = "hackathon"
    Project     = "LiveInsight"
  }
}

# API Gateway /events 리소스
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "events"
}

# POST 메서드
resource "aws_api_gateway_method" "events_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
}

# OPTIONS 메서드 (CORS)
resource "aws_api_gateway_method" "events_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Lambda 통합
resource "aws_api_gateway_integration" "events_post" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.event_collector.invoke_arn
}

# CORS 통합
resource "aws_api_gateway_integration" "events_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# CORS 응답
resource "aws_api_gateway_method_response" "events_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "events_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_options.http_method
  status_code = aws_api_gateway_method_response.events_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda 권한
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_collector.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API 배포
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_method.events_post,
    aws_api_gateway_method.events_options,
    aws_api_gateway_integration.events_post,
    aws_api_gateway_integration.events_options
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "prod"
}

# Django 웹 애플리케이션 모듈
module "web_app" {
  source = "./web-app"
  
  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment
  
  # S3 버킷 정보 전달
  static_files_bucket = aws_s3_bucket.static_files.bucket
  alb_logs_bucket     = aws_s3_bucket.alb_logs.bucket
}

# Phase 7: 고급 모니터링 모듈
module "advanced_monitoring" {
  source = "./monitoring"
  
  aws_region             = var.aws_region
  alb_arn_suffix         = module.web_app.alb_arn_suffix
  lambda_function_name   = aws_lambda_function.event_collector.function_name
  lambda_log_group_name  = "/aws/lambda/${aws_lambda_function.event_collector.function_name}"
  events_table_name      = aws_dynamodb_table.events.name
  ecs_service_name       = module.web_app.ecs_service_name
  ecs_cluster_name       = module.web_app.ecs_cluster_name
}