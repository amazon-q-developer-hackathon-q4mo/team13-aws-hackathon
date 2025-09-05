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

## 완료 기준
- [ ] Lambda 함수 메모리 및 성능 최적화 완료
- [ ] 구조화된 로깅 시스템 구현
- [ ] CloudWatch 커스텀 메트릭 설정
- [ ] 부하 테스트 완료 및 결과 분석
- [ ] 성능 모니터링 대시보드 구성