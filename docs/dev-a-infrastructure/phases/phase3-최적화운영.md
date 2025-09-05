# Phase 3: 최적화 및 운영 준비 (12-18시간)

## 🎯 Phase 목표
- 성능 최적화 및 병목 해결
- 운영 환경 안정화
- 모니터링 고도화
- 데모 환경 완성

## ⏰ 세부 작업 일정

### 1단계: 성능 최적화 (90분)
#### 작업 내용
- [ ] Lambda 함수 성능 튜닝
- [ ] DynamoDB 성능 최적화
- [ ] API Gateway 캐싱 설정
- [ ] CloudFront 캐시 정책 최적화

#### Lambda 최적화
```hcl
# Lambda 함수 메모리 및 타임아웃 조정 (Phase 1에서 계획된 최적화)
resource "aws_lambda_function" "event_collector" {
  memory_size = 512  # Phase 1 256MB → 512MB (성능 향상)
  timeout     = 15   # Phase 1 30초 → 15초 (비용 절약)
  
  # 예약된 동시 실행 설정
  reserved_concurrent_executions = 100
}
```

#### DynamoDB 최적화
```hcl
# DynamoDB 자동 스케일링 설정 (필요시)
resource "aws_appautoscaling_target" "events_table_read" {
  max_capacity       = 100
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.events.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}
```

#### API Gateway 캐싱
```hcl
# 캐싱 설정 (실시간 데이터는 짧게, 통계는 길게)
resource "aws_api_gateway_method_settings" "realtime" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_deployment.main.stage_name
  method_path = "*/realtime/GET"
  
  settings {
    caching_enabled      = true
    cache_ttl_in_seconds = 3  # 3초 캐시
  }
}
```

#### 체크리스트
- [ ] Lambda 메모리 최적화 완료
- [ ] DynamoDB 읽기/쓰기 용량 최적화
- [ ] API Gateway 캐싱 설정
- [ ] CloudFront 캐시 정책 적용

### 2단계: 보안 강화 (60분)
#### 작업 내용
- [ ] API Key 인증 시스템 구현
- [ ] Rate Limiting 설정
- [ ] WAF 기본 설정 (선택사항)
- [ ] 보안 그룹 최적화

#### API Key 인증
```hcl
# API Key 생성
resource "aws_api_gateway_api_key" "liveinsight" {
  name        = "liveinsight-api-key-${var.environment}"
  description = "API key for LiveInsight tracking"
}

# Usage Plan 설정
resource "aws_api_gateway_usage_plan" "liveinsight" {
  name = "liveinsight-usage-plan-${var.environment}"
  
  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }
  
  throttle_settings {
    rate_limit  = 1000  # 초당 1000 요청
    burst_limit = 2000  # 버스트 2000 요청
  }
}
```

#### Rate Limiting
```hcl
# 메서드별 Rate Limiting
resource "aws_api_gateway_method_settings" "events" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_deployment.main.stage_name
  method_path = "*/events/POST"
  
  settings {
    throttling_rate_limit  = 500   # 초당 500 요청
    throttling_burst_limit = 1000  # 버스트 1000 요청
  }
}
```

#### 체크리스트
- [ ] API Key 생성 및 Usage Plan 설정
- [ ] Rate Limiting 적용
- [ ] HTTPS 강제 설정
- [ ] 보안 헤더 추가

### 3단계: 모니터링 고도화 (75분)
#### 작업 내용
- [ ] CloudWatch 대시보드 생성
- [ ] 커스텀 메트릭 설정
- [ ] 알람 정책 고도화
- [ ] 로그 분석 설정

#### CloudWatch 대시보드
```hcl
resource "aws_cloudwatch_dashboard" "liveinsight" {
  dashboard_name = "LiveInsight-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.event_collector.function_name],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.event_collector.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.event_collector.function_name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Metrics"
        }
      }
    ]
  })
}
```

#### 커스텀 메트릭
```hcl
# DynamoDB 메트릭 알람
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  alarm_name          = "liveinsight-dynamodb-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DynamoDB throttling detected"
  
  dimensions = {
    TableName = aws_dynamodb_table.events.name
  }
}
```

#### 체크리스트
- [ ] CloudWatch 대시보드 생성
- [ ] 주요 메트릭 알람 설정
- [ ] 로그 인사이트 쿼리 준비
- [ ] 비용 알람 설정

### 4단계: 데모 환경 준비 (45분)
#### 작업 내용
- [ ] 샘플 데이터 생성 스크립트
- [ ] 데모 시나리오 테스트
- [ ] 성능 벤치마크 실행
- [ ] 문서 업데이트

#### 샘플 데이터 스크립트
```python
# scripts/generate_sample_data.py
import boto3
import json
import time
from datetime import datetime, timedelta

def generate_sample_events():
    """데모용 샘플 이벤트 생성"""
    dynamodb = boto3.resource('dynamodb')
    events_table = dynamodb.Table('liveinsight-events-dev')
    
    # 최근 1시간 동안의 샘플 이벤트 생성
    base_time = int(time.time()) - 3600
    
    for i in range(100):  # 100개 샘플 이벤트
        event = {
            'session_id': f'demo_session_{i % 10}',
            'timestamp': base_time + (i * 36),
            'event_type': 'page_view',
            'page_url': f'https://demo.com/page{i % 5}',
            'ttl': int(time.time()) + 86400
        }
        events_table.put_item(Item=event)
```

#### 성능 벤치마크
```bash
# scripts/benchmark.sh
#!/bin/bash

echo "🔥 성능 벤치마크 시작..."

# API 응답시간 테스트
for i in {1..10}; do
  curl -w "@curl-format.txt" -s -o /dev/null \
    https://api-url/api/realtime
done

# 동시 요청 테스트
ab -n 1000 -c 10 https://api-url/api/events
```

#### 체크리스트
- [ ] 샘플 데이터 생성 완료
- [ ] 데모 시나리오 검증
- [ ] 성능 벤치마크 실행
- [ ] API 문서 업데이트

### 5단계: 운영 환경 안정화 (30분)
#### 작업 내용
- [ ] 백업 정책 설정
- [ ] 장애 복구 절차 문서화
- [ ] 운영 체크리스트 작성
- [ ] 비용 최적화 검토

#### 백업 설정
```hcl
# DynamoDB 백업 설정
resource "aws_dynamodb_table" "events" {
  # ... 기존 설정 ...
  
  point_in_time_recovery {
    enabled = true
  }
  
  # 온디맨드 백업 (선택사항)
  tags = {
    BackupSchedule = "daily"
  }
}
```

#### 체크리스트
- [ ] DynamoDB 백업 활성화
- [ ] Lambda 함수 버전 관리
- [ ] CloudFormation 스택 보호 설정
- [ ] 비용 알람 임계값 설정

## 🤝 담당자 B 협업 포인트

### 14시간 체크포인트
**목적**: 성능 최적화 결과 공유
**협의 내용**:
- API 응답시간 개선 결과
- 캐싱 정책 영향도 확인
- 추가 최적화 요구사항

### 16시간 체크포인트
**목적**: 데모 환경 테스트
**협업 내용**:
- 샘플 데이터로 대시보드 테스트
- 실시간 기능 동작 확인
- 데모 시나리오 리허설

## 🚨 리스크 및 대응

### 주요 리스크
1. **성능 최적화 부작용**
   - 대응: 단계별 적용 후 검증
   - 백업: 이전 설정으로 즉시 롤백

2. **캐싱으로 인한 데이터 지연**
   - 대응: TTL 값 조정 (3초 → 1초)
   - 백업: 캐싱 비활성화

3. **모니터링 알람 오탐**
   - 대응: 임계값 조정
   - 백업: 알람 일시 비활성화

### 긴급 대응
```bash
# 성능 문제 발생 시 즉시 롤백
terraform apply -target=aws_lambda_function.event_collector \
  -var="lambda_memory=256"

# 캐싱 문제 발생 시 비활성화
aws apigateway update-stage \
  --rest-api-id $API_ID \
  --stage-name prod \
  --patch-ops op=replace,path=/cacheClusterEnabled,value=false
```

## 📊 성공 지표

### 성능 목표
- [ ] API 응답시간 < 100ms (P95)
- [ ] Lambda 콜드 스타트 < 1초
- [ ] DynamoDB 응답시간 < 10ms
- [ ] CloudFront 캐시 히트율 > 80%

### 운영 목표
- [ ] 모니터링 대시보드 완성
- [ ] 알람 정책 검증 완료
- [ ] 백업 및 복구 절차 문서화
- [ ] 데모 환경 안정화

## 🔄 Phase 3 완료 기준
- ✅ 성능 최적화 완료 및 벤치마크 통과
- ✅ 보안 설정 강화 완료
- ✅ 모니터링 고도화 완료
- ✅ 데모 환경 완성 및 테스트 통과
- ✅ 운영 문서 작성 완료

**Phase 3 완료 시 Phase 4 (데모 준비)로 진행!** 🎯