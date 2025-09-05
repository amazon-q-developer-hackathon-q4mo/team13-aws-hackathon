# Phase 3: 최적화 및 운영 준비 (12-18시간)

## 📊 현재 진행 상황 (85% 완료)
### ✅ 완료된 작업
- [x] 보안 설정 강화 (CSRF, 입력 검증, S3 보안)
- [x] 코드 중복 제거 (Terraform 최적화 135줄 감소)
- [x] 모니터링 대시보드 구성 (CloudWatch 알람 8개)
- [x] 운영 환경 배포 준비 (terraform apply 완료)

### 🔄 진행 중인 작업
- [ ] **담당자 B 코드 통합 배포 지원** ⬅️ **현재 작업**
- [ ] 성능 테스트 및 병목 현상 해결
- [ ] 최종 보안 검토 및 문서화

## 🎯 Phase 목표
- ~~성능 최적화 및 병목 해결~~ → **담당자 B 코드 통합 우선**
- 운영 환경 안정화
- 모니터링 고도화
- 데모 환경 완성

## ⏰ 세부 작업 일정 (수정된 계획)

### 🚀 우선 작업: 담당자 B 코드 통합 배포 (45-60분) ⬅️ **현재 진행**
#### 작업 내용
- [ ] Lambda 배포 패키지 준비 (20분)
- [ ] 실제 코드 배포 (25분)
- [ ] API 엔드포인트 테스트 (15분)
- [ ] 문제 해결 및 디버깅 (예비 시간)

#### Lambda 배포 패키지 준비
```bash
# 1. lambda_function.py 핸들러 경로 수정
cat > lambda_function.py << EOF
from src.main import handler

def lambda_handler(event, context):
    return handler(event, context)
EOF

# 2. requirements.txt 확인 및 업데이트
cat > requirements.txt << EOF
fastapi==0.104.1
mangum==0.17.0
boto3==1.34.0
pydantic==2.5.0
pydantic-settings==2.1.0
EOF

# 3. 소스 코드 패키징 (의존성 먼저 설치)
mkdir -p package
pip install -r requirements.txt -t package/
cp -r src/ package/
cp lambda_function.py package/
cd package && zip -r ../lambda-deployment.zip . && cd ..

# 4. 배포 패키지 크기 확인 (50MB 제한)
ls -lh lambda-deployment.zip
```

#### 실제 코드 배포
```bash
# 각 Lambda 함수별 개별 배포
for func in event-collector realtime-api stats-api; do
  echo "Deploying $func..."
  aws lambda update-function-code \
    --function-name "liveinsight-$func-dev" \
    --zip-file fileb://lambda-deployment.zip
  
  # 환경변수 확인
  aws lambda get-function-configuration \
    --function-name "liveinsight-$func-dev" \
    --query 'Environment.Variables'
done
```

#### API 엔드포인트 테스트
```bash
# 1. CSRF 토큰 발급 테스트
curl -X POST https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/csrf-token \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test_session"}'

# 2. POST /api/events 테스트 (CSRF 토큰 포함)
curl -X POST https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/events \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: YOUR_TOKEN" \
  -H "X-Session-ID: test_session" \
  -d '{"event_type":"page_view","session_id":"test_session","page_url":"https://test.com"}'

# 3. GET /api/realtime 테스트
curl https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/realtime

# 4. GET /api/stats 테스트
curl https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/stats

# 5. CloudWatch 로그 확인
aws logs tail /aws/lambda/liveinsight-event-collector-dev --follow
```

#### 체크리스트
- [ ] `lambda_function.py` 핸들러 경로 수정 (`src.main` 사용)
- [ ] 모든 의존성 패키지 포함 확인 (package/ 디렉토리)
- [ ] 배포 패키지 크기 < 50MB 확인
- [ ] 환경변수 `EVENTS_TABLE`, `SESSIONS_TABLE` 설정 확인
- [ ] 3개 Lambda 함수 모두 배포 성공
- [ ] CloudWatch 로그 정상 출력 확인
- [ ] 모든 API 엔드포인트 200 응답 확인
- [ ] CSRF 토큰 엔드포인트 동작 확인

### 1단계: 성능 최적화 (90분) → **코드 통합 후 진행**
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
- [ ] 담당자 B와 통합 테스트
- [ ] 데모 시나리오 테스트
- [ ] 성능 벤치마크 실행
- [ ] 문서 업데이트

#### 담당자 B 통합 테스트
```bash
# 통합 테스트 시나리오
# 1. 이벤트 수집 → DynamoDB 저장 확인
# 2. 실시간 데이터 조회 → 캐시 동작 확인
# 3. 통계 데이터 조회 → 집계 로직 확인
# 4. CSRF 토큰 → 보안 기능 확인
```

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

### 즉시 협업: 코드 통합 배포
**목적**: 실제 Lambda 코드 배포 및 테스트
**협의 내용**:
- `src/main.py` 핸들러 경로 확인
- 환경변수 및 DynamoDB 스키마 최종 확인
- API 엔드포인트 동작 검증
- CSRF 토큰 시스템 테스트

### 14시간 체크포인트
**목적**: 통합 테스트 및 성능 확인
**협의 내용**:
- 전체 시스템 통합 테스트
- API 응답시간 및 성능 확인
- 추가 최적화 요구사항
- 데모 시나리오 준비

### 16시간 체크포인트
**목적**: 데모 환경 최종 검증
**협업 내용**:
- 샘플 데이터로 대시보드 테스트
- 실시간 기능 동작 확인
- 데모 시나리오 리허설
- 최종 문서화

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
- ✅ 보안 설정 강화 완료 (CSRF, 입력 검증, S3 보안)
- ✅ 코드 중복 제거 완료 (Terraform 최적화)
- ✅ 모니터링 고도화 완료 (CloudWatch 알람 8개)
- [ ] **담당자 B 코드 통합 배포 완료** ⬅️ **진행 중**
- [ ] 성능 최적화 완료 및 벤치마크 통과
- [ ] 데모 환경 완성 및 테스트 통과
- [ ] 운영 문서 작성 완료

## ⏰ 예상 완료 시간
- **현재 진행률**: 85% 완료
- **남은 작업**: 담당자 B 코드 통합 (45-60분) + 성능 테스트 (30-45분)
- **예상 완료**: 1.5-2.5시간 내
- **비상 계획**: 문제 발생 시 +30-60분 추가

**Phase 3 완료 시 Phase 4 (데모 준비)로 진행!** 🎯