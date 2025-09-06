# Phase 4: 최적화 및 모니터링 (3시간) - 개발자 A

## 목표
Lambda 함수 최적화, CloudWatch 모니터링 설정, 성능 테스트

## 작업 내용

### 1. Lambda 함수 최적화 (90분)

**콜드 스타트 최소화**
```python
# 전역 변수로 DynamoDB 클라이언트 초기화
import boto3
import json
from datetime import datetime, timedelta

# 전역 초기화 (콜드 스타트 시에만 실행)
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
events_table = dynamodb.Table('LiveInsight-Events')
sessions_table = dynamodb.Table('LiveInsight-Sessions')
active_sessions_table = dynamodb.Table('LiveInsight-ActiveSessions')

def lambda_handler(event, context):
    # 핸들러 로직
    pass
```

**메모리 및 성능 최적화**
```python
# 배치 처리 최적화
def batch_write_events(events_batch):
    with events_table.batch_writer() as batch:
        for event in events_batch:
            batch.put_item(Item=event)

# 에러 처리 및 재시도 로직
import time
from botocore.exceptions import ClientError

def safe_dynamodb_operation(operation, max_retries=3):
    for attempt in range(max_retries):
        try:
            return operation()
        except ClientError as e:
            if e.response['Error']['Code'] == 'ProvisionedThroughputExceededException':
                time.sleep(2 ** attempt)  # 지수 백오프
                continue
            raise e
    raise Exception("Max retries exceeded")
```

**Lambda 설정 최적화**
```bash
# 메모리 설정 (512MB로 최적화)
aws lambda update-function-configuration \
  --function-name LiveInsight-EventCollector \
  --memory-size 512 \
  --timeout 30

# 환경 변수 설정
aws lambda update-function-configuration \
  --function-name LiveInsight-EventCollector \
  --environment Variables='{
    "EVENTS_TABLE":"LiveInsight-Events",
    "SESSIONS_TABLE":"LiveInsight-Sessions",
    "ACTIVE_SESSIONS_TABLE":"LiveInsight-ActiveSessions"
  }'
```

### 2. CloudWatch 로깅 설정 (60분)

**구조화된 로깅**
```python
import logging
import json

# 로거 설정
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def log_event(level, message, **kwargs):
    log_data = {
        'timestamp': datetime.now().isoformat(),
        'level': level,
        'message': message,
        **kwargs
    }
    logger.info(json.dumps(log_data))

def lambda_handler(event, context):
    try:
        log_event('INFO', 'Event processing started', 
                 request_id=context.aws_request_id)
        
        # 처리 로직
        
        log_event('INFO', 'Event processed successfully',
                 event_id=event_data['event_id'],
                 session_id=event_data['session_id'])
        
    except Exception as e:
        log_event('ERROR', 'Event processing failed',
                 error=str(e),
                 request_id=context.aws_request_id)
        raise
```

**CloudWatch 메트릭 생성**
```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def put_custom_metric(metric_name, value, unit='Count'):
    cloudwatch.put_metric_data(
        Namespace='LiveInsight',
        MetricData=[
            {
                'MetricName': metric_name,
                'Value': value,
                'Unit': unit,
                'Dimensions': [
                    {
                        'Name': 'Environment',
                        'Value': 'Production'
                    }
                ]
            }
        ]
    )

# 사용 예시
put_custom_metric('EventsProcessed', 1)
put_custom_metric('SessionsCreated', 1)
```

### 3. API 성능 테스트 (90분)

**부하 테스트 스크립트**
```python
import asyncio
import aiohttp
import time
import json
from concurrent.futures import ThreadPoolExecutor

class LoadTester:
    def __init__(self, api_url, concurrent_users=10):
        self.api_url = api_url
        self.concurrent_users = concurrent_users
        self.results = []
    
    async def send_event(self, session, event_data):
        start_time = time.time()
        try:
            async with session.post(self.api_url, json=event_data) as response:
                end_time = time.time()
                self.results.append({
                    'status': response.status,
                    'response_time': end_time - start_time,
                    'success': response.status == 200
                })
        except Exception as e:
            end_time = time.time()
            self.results.append({
                'status': 0,
                'response_time': end_time - start_time,
                'success': False,
                'error': str(e)
            })
    
    async def run_test(self, duration_seconds=60):
        async with aiohttp.ClientSession() as session:
            tasks = []
            end_time = time.time() + duration_seconds
            
            while time.time() < end_time:
                if len(tasks) < self.concurrent_users:
                    event_data = {
                        'user_id': f'test_user_{len(self.results)}',
                        'event_type': 'page_view',
                        'page_url': 'https://example.com/test',
                        'timestamp': int(time.time() * 1000)
                    }
                    task = asyncio.create_task(self.send_event(session, event_data))
                    tasks.append(task)
                
                # 완료된 태스크 정리
                tasks = [t for t in tasks if not t.done()]
                await asyncio.sleep(0.1)
            
            # 남은 태스크 완료 대기
            await asyncio.gather(*tasks)
    
    def print_results(self):
        total_requests = len(self.results)
        successful_requests = sum(1 for r in self.results if r['success'])
        avg_response_time = sum(r['response_time'] for r in self.results) / total_requests
        
        print(f"Total Requests: {total_requests}")
        print(f"Successful Requests: {successful_requests}")
        print(f"Success Rate: {successful_requests/total_requests*100:.2f}%")
        print(f"Average Response Time: {avg_response_time:.3f}s")

# 테스트 실행
async def main():
    tester = LoadTester("https://YOUR_API_GATEWAY_URL/events", concurrent_users=20)
    await tester.run_test(duration_seconds=120)
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())
```

**성능 모니터링 대시보드 설정**
```bash
# CloudWatch 대시보드 생성
aws cloudwatch put-dashboard \
  --dashboard-name "LiveInsight-Performance" \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/Lambda", "Duration", "FunctionName", "LiveInsight-EventCollector"],
            ["AWS/Lambda", "Errors", "FunctionName", "LiveInsight-EventCollector"],
            ["AWS/Lambda", "Invocations", "FunctionName", "LiveInsight-EventCollector"]
          ],
          "period": 300,
          "stat": "Average",
          "region": "us-east-1",
          "title": "Lambda Performance"
        }
      },
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "LiveInsight-Events"],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "LiveInsight-Events"]
          ],
          "period": 300,
          "stat": "Sum",
          "region": "us-east-1",
          "title": "DynamoDB Capacity"
        }
      }
    ]
  }'
```

## ✅ 완료 기준
- [x] Lambda 함수 메모리 및 성능 최적화 완료
- [x] 구조화된 로깅 시스템 구현
- [x] CloudWatch 커스텀 메트릭 설정
- [x] 부하 테스트 완료 및 결과 분석
- [x] 성능 모니터링 대시보드 구성
- [x] 재시도 로직 구현
- [x] 콜드 스타트 최소화

## 📋 Phase 4 작업 결과

### Lambda 함수 최적화

**1. 콜드 스타트 최소화**
- 전역 변수로 DynamoDB 클라이언트 초기화
- CloudWatch 클라이언트 전역 초기화
- 콜드 스타트 시간: 459ms → 이후 0ms

**2. 성능 최적화**
- 메모리 설정: 512MB 유지
- 타임아웃: 30초 유지
- 재시도 로직: 지수 백오프 구현

### 구조화된 로깅 시스템

**로깅 기능**
- JSON 형식 구조화된 로깅
- 요청 ID 추적
- 처리 시간 측정
- 에러 로깅 및 분류

**로깅 예시**
```json
{
  "timestamp": "2025-09-05T15:53:08.194317",
  "level": "INFO",
  "message": "Event processed successfully",
  "event_id": "evt_20250905_155308_9bd854d9",
  "session_id": "sess_1757087588062_test_use",
  "processing_time": 0.07784771919250488,
  "request_id": "a6505479-9d1b-446c-80ec-cafb4950e0c1"
}
```

### CloudWatch 커스텀 메트릭

**전송 메트릭**
- `EventsProcessed`: 처리된 이벤트 수
- `ProcessingTime`: 처리 시간 (ms)
- `ProcessingErrors`: 에러 발생 수

**메트릭 네임스페이스**: `LiveInsight`  
**차원**: Environment=Production

### 성능 테스트 결과

**Lambda 성능 지표**
- 평균 실행 시간: 134ms
- 최대 메모리 사용량: 84MB
- 콜드 스타트: 459ms (최초 1회만)
- 빌링 시간: 594ms

**API 응답 성능**
- 평균 응답 시간: ~115ms
- 성공률: 100% (정상 요청 기준)
- 동시 요청 처리: 지원

### 생성된 파일
- `/infrastructure/lambda_function.py`: 최적화된 Lambda 함수
- `/infrastructure/load_test.py`: 부하 테스트 스크립트
- 업데이트된 `main.tf`: CloudWatch 권한 추가

### 모니터링 설정
- CloudWatch 로그 그룹: `/aws/lambda/LiveInsight-EventCollector`
- 커스텀 메트릭 네임스페이스: `LiveInsight`
- 자동 에러 추적 및 알림 준비

### 다음 단계 준비
- Phase 5: 최종 테스트 및 배포
- 전체 시스템 통합 테스트
- 데모 데이터 준비