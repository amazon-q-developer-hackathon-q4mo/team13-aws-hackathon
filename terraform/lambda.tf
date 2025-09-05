# 더미 Lambda 코드 압축
data "archive_file" "lambda_dummy" {
  type        = "zip"
  source_file = "${path.module}/../lambda_dummy/dummy.py"
  output_path = "${path.module}/lambda_dummy.zip"
}

# Lambda 함수 공통 설정
locals {
  lambda_functions = {
    event_collector = "event-collector"
    realtime_api    = "realtime-api"
    stats_api       = "stats-api"
  }
  
  lambda_common_config = {
    runtime         = "python3.11"
    timeout         = var.lambda_timeout
    memory_size     = var.lambda_memory
    handler         = "dummy.handler"
    environment_variables = {
      EVENTS_TABLE   = aws_dynamodb_table.events.name
      SESSIONS_TABLE = aws_dynamodb_table.sessions.name
    }
  }
}

# Lambda 함수들 (for_each로 통합)
resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions
  
  filename         = data.archive_file.lambda_dummy.output_path
  function_name    = "${var.project_name}-${each.value}-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = local.lambda_common_config.handler
  runtime         = local.lambda_common_config.runtime
  timeout         = local.lambda_common_config.timeout
  memory_size     = local.lambda_common_config.memory_size
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256

  environment {
    variables = local.lambda_common_config.environment_variables
  }

  tags = {
    Name = "${var.project_name}-${each.value}"
  }
}

# 개별 함수 참조를 위한 locals
locals {
  event_collector = aws_lambda_function.functions["event_collector"]
  realtime_api    = aws_lambda_function.functions["realtime_api"]
  stats_api       = aws_lambda_function.functions["stats_api"]
}