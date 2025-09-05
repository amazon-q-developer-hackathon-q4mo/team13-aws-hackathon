# API Gateway 공통 설정
locals {
  cors_headers = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  
  cors_response_headers = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-API-Key,Authorization,X-CSRF-Token,X-Session-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  
  api_endpoints = {
    events = {
      path_part = "events"
      method    = "POST"
      lambda    = local.event_collector
    }
    realtime = {
      path_part = "realtime"
      method    = "GET"
      lambda    = local.realtime_api
    }
    stats = {
      path_part = "stats"
      method    = "GET"
      lambda    = local.stats_api
    }
  }
}

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
    aws_api_gateway_method.endpoint_method,
    aws_api_gateway_method.endpoint_options,
    aws_api_gateway_integration.endpoint_integration,
    aws_api_gateway_integration.endpoint_options,
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

# API 엔드포인트 리소스들 (for_each로 통합)
resource "aws_api_gateway_resource" "endpoints" {
  for_each = local.api_endpoints
  
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = each.value.path_part
}

# API 엔드포인트 메서드들 (for_each로 통합)
resource "aws_api_gateway_method" "endpoint_method" {
  for_each = local.api_endpoints
  
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.endpoints[each.key].id
  http_method   = each.value.method
  authorization = "NONE"
}

# API 엔드포인트 통합들 (for_each로 통합)
resource "aws_api_gateway_integration" "endpoint_integration" {
  for_each = local.api_endpoints
  
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.endpoints[each.key].id
  http_method = aws_api_gateway_method.endpoint_method[each.key].http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = each.value.lambda.invoke_arn
}

# CORS OPTIONS 메서드들 (for_each로 통합)
resource "aws_api_gateway_method" "endpoint_options" {
  for_each = local.api_endpoints
  
  rest_api_id   = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id   = aws_api_gateway_resource.endpoints[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "endpoint_options" {
  for_each = local.api_endpoints
  
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.endpoints[each.key].id
  http_method = aws_api_gateway_method.endpoint_options[each.key].http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "endpoint_options" {
  for_each = local.api_endpoints
  
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.endpoints[each.key].id
  http_method = aws_api_gateway_method.endpoint_options[each.key].http_method
  status_code = "200"

  response_parameters = local.cors_headers
}

resource "aws_api_gateway_integration_response" "endpoint_options" {
  for_each = local.api_endpoints
  
  rest_api_id = aws_api_gateway_rest_api.liveinsight_api.id
  resource_id = aws_api_gateway_resource.endpoints[each.key].id
  http_method = aws_api_gateway_method.endpoint_options[each.key].http_method
  status_code = aws_api_gateway_method_response.endpoint_options[each.key].status_code

  response_parameters = local.cors_response_headers
}

# Lambda 권한 설정 (for_each로 통합)
resource "aws_lambda_permission" "api_gateway_invoke" {
  for_each = local.api_endpoints
  
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.liveinsight_api.execution_arn}/*/*"
}