# Events 테이블 - 이벤트 데이터 저장
resource "aws_dynamodb_table" "events" {
  name           = "${var.project_name}-events-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"
  range_key      = "timestamp"

  attribute {
    name = "session_id"
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

  # 이벤트 타입별 조회를 위한 GSI
  global_secondary_index {
    name            = "EventTypeIndex"
    hash_key        = "event_type"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # 24시간 후 자동 삭제
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Point-in-Time Recovery 활성화
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-events"
  }
}

# Sessions 테이블 - 세션 정보 저장
resource "aws_dynamodb_table" "sessions" {
  name           = "${var.project_name}-sessions-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "is_active"
    type = "S"
  }

  attribute {
    name = "last_activity"
    type = "N"
  }

  # 활성 세션 조회를 위한 GSI
  global_secondary_index {
    name            = "ActivityIndex"
    hash_key        = "is_active"
    range_key       = "last_activity"
    projection_type = "ALL"
  }

  # Point-in-Time Recovery 활성화
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-sessions"
  }
}