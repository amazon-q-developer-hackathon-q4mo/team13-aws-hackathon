# 더미 Lambda 코드 압축
data "archive_file" "lambda_dummy" {
  type        = "zip"
  source_file = "${path.module}/../lambda_dummy/dummy.py"
  output_path = "${path.module}/lambda_dummy.zip"
}

# Event Collector Lambda 함수
resource "aws_lambda_function" "event_collector" {
  filename         = data.archive_file.lambda_dummy.output_path
  function_name    = "${var.project_name}-event-collector-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "dummy.handler"
  runtime         = "python3.11"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256

  environment {
    variables = {
      EVENTS_TABLE   = aws_dynamodb_table.events.name
      SESSIONS_TABLE = aws_dynamodb_table.sessions.name
    }
  }

  tags = {
    Name = "${var.project_name}-event-collector"
  }
}

# Realtime API Lambda 함수
resource "aws_lambda_function" "realtime_api" {
  filename         = data.archive_file.lambda_dummy.output_path
  function_name    = "${var.project_name}-realtime-api-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "dummy.handler"
  runtime         = "python3.11"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256

  environment {
    variables = {
      EVENTS_TABLE   = aws_dynamodb_table.events.name
      SESSIONS_TABLE = aws_dynamodb_table.sessions.name
    }
  }

  tags = {
    Name = "${var.project_name}-realtime-api"
  }
}

# Stats API Lambda 함수
resource "aws_lambda_function" "stats_api" {
  filename         = data.archive_file.lambda_dummy.output_path
  function_name    = "${var.project_name}-stats-api-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "dummy.handler"
  runtime         = "python3.11"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256

  environment {
    variables = {
      EVENTS_TABLE   = aws_dynamodb_table.events.name
      SESSIONS_TABLE = aws_dynamodb_table.sessions.name
    }
  }

  tags = {
    Name = "${var.project_name}-stats-api"
  }
}