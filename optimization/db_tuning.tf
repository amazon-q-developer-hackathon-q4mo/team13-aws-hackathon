# DynamoDB 성능 최적화 설정

# Events 테이블 최적화
resource "aws_dynamodb_table" "events_optimized" {
  name           = "LiveInsight-Events-Optimized"
  billing_mode   = "PAY_PER_REQUEST"  # 트래픽 패턴에 따라 자동 조정
  hash_key       = "user_id"
  range_key      = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "event_type"
    type = "S"
  }

  attribute {
    name = "page_url"
    type = "S"
  }

  # 이벤트 타입별 조회를 위한 GSI
  global_secondary_index {
    name            = "EventTypeIndex"
    hash_key        = "event_type"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # 페이지별 조회를 위한 GSI
  global_secondary_index {
    name            = "PageUrlIndex"
    hash_key        = "page_url"
    range_key       = "timestamp"
    projection_type = "INCLUDE"
    non_key_attributes = ["user_id", "event_type"]
  }

  # TTL 설정 (90일 후 자동 삭제)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "LiveInsight-Events-Optimized"
    Environment = "production"
  }
}

# Sessions 테이블 최적화
resource "aws_dynamodb_table" "sessions_optimized" {
  name           = "LiveInsight-Sessions-Optimized"
  billing_mode   = "PAY_PER_REQUEST"
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

  # 사용자별 세션 조회를 위한 GSI
  global_secondary_index {
    name            = "UserSessionsIndex"
    hash_key        = "user_id"
    range_key       = "start_time"
    projection_type = "ALL"
  }

  # TTL 설정 (30일 후 자동 삭제)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "LiveInsight-Sessions-Optimized"
    Environment = "production"
  }
}

# ActiveSessions 테이블 최적화
resource "aws_dynamodb_table" "active_sessions_optimized" {
  name           = "LiveInsight-ActiveSessions-Optimized"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "last_activity"
    type = "N"
  }

  # 최근 활동 시간별 조회를 위한 GSI
  global_secondary_index {
    name            = "LastActivityIndex"
    hash_key        = "last_activity"
    projection_type = "ALL"
  }

  # TTL 설정 (30분 후 자동 삭제)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "LiveInsight-ActiveSessions-Optimized"
    Environment = "production"
  }
}

# DynamoDB 성능 모니터링
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "DynamoDB-ReadThrottledRequests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB read throttling"

  dimensions = {
    TableName = aws_dynamodb_table.events_optimized.name
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "DynamoDB-WriteThrottledRequests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB write throttling"

  dimensions = {
    TableName = aws_dynamodb_table.events_optimized.name
  }
}

# 출력
output "optimized_tables" {
  value = {
    events_table          = aws_dynamodb_table.events_optimized.name
    sessions_table        = aws_dynamodb_table.sessions_optimized.name
    active_sessions_table = aws_dynamodb_table.active_sessions_optimized.name
  }
}