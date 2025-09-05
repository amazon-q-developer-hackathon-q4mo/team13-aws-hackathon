# API Gateway REST API
resource "aws_api_gateway_rest_api" "liveinsight_api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "LiveInsight Analytics API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "liveinsight_api" {
  depends_on = [
    aws_api_gateway_method.events_post,
    aws_api_gateway_method.realtime_get,
    aws_api_gateway_method.stats_get,
    aws_api_gateway_method.events_options,
    aws_api_gateway_method.realtime_options,
    aws_api_gateway_method.stats_options,
  ]

  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  stage_name  = var.environment

  lifecycle {
    create_before_destroy = true
  }
}

# /api 리소스
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  parent_id   = aws_api_gateway_rest_api.liveinsight_api.root_resource_id
  path_part   = "api"
}

# /api/events 리소스
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "events"
}

# /api/realtime 리소스
resource "aws_api_gateway_resource" "realtime" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "realtime"
}

# /api/stats 리소스
resource "aws_api_gateway_resource" "stats" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "stats"
}

# POST /api/events
resource "aws_api_gateway_method" "events_post" {
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "events_post" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.event_collector.invoke_arn
}

# GET /api/realtime
resource "aws_api_gateway_method" "realtime_get" {
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.realtime.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "realtime_get" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.realtime.id
  http_method = aws_api_gateway_method.realtime_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.realtime_api.invoke_arn
}

# GET /api/stats
resource "aws_api_gateway_method" "stats_get" {
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.stats.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "stats_get" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.stats.id
  http_method = aws_api_gateway_method.stats_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.stats_api.invoke_arn
}

# CORS OPTIONS 메서드들
resource "aws_api_gateway_method" "events_options" {
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "events_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "events_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
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
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_options.http_method
  status_code = aws_api_gateway_method_response.events_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-API-Key,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# realtime OPTIONS
resource "aws_api_gateway_method" "realtime_options" {
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.realtime.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "realtime_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.realtime.id
  http_method = aws_api_gateway_method.realtime_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "realtime_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.realtime.id
  http_method = aws_api_gateway_method.realtime_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "realtime_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.realtime.id
  http_method = aws_api_gateway_method.realtime_options.http_method
  status_code = aws_api_gateway_method_response.realtime_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-API-Key,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# stats OPTIONS
resource "aws_api_gateway_method" "stats_options" {
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.stats.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "stats_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.stats.id
  http_method = aws_api_gateway_method.stats_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "stats_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.stats.id
  http_method = aws_api_gateway_method.stats_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "stats_options" {
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.stats.id
  http_method = aws_api_gateway_method.stats_options.http_method
  status_code = aws_api_gateway_method_response.stats_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-API-Key,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda 권한 설정
resource "aws_lambda_permission" "api_gateway_event_collector" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_collector.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.liveinsight_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_realtime_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.realtime_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.liveinsight_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_stats_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stats_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.liveinsight_api.execution_arn}/*/*"
}