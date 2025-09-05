# LiveInsight 백엔드 개발 명세서 (담당자 B)

## 개발 목표
실시간 웹 분석 서비스의 핵심 비즈니스 로직과 API 엔드포인트 구현 (24시간 해커톤 MVP)

## 기술 스택
- **언어**: Python 3.11
- **프레임워크**: FastAPI + Mangum (Lambda 어댑터)
- **데이터베이스**: DynamoDB (On-Demand)
- **패키지 관리**: uv
- **배포**: AWS Lambda (서버리스)
- **인증**: API Key 기반 (단순화)

## 프로젝트 구조
```
src/
├── handlers/
│   ├── event_collector.py    # POST /api/events
│   ├── realtime_api.py       # GET /api/realtime
│   └── stats_api.py          # GET /api/stats
├── models/
│   ├── events.py             # Event 모델
│   └── sessions.py           # Session 모델
├── services/
│   ├── dynamodb.py           # DynamoDB 서비스
│   └── analytics.py          # 분석 로직
├── utils/
│   ├── response.py           # HTTP 응답 헬퍼
│   └── validation.py         # 데이터 검증
└── main.py                   # FastAPI 메인 앱
```

## API 엔드포인트 명세

### 1. 이벤트 수집 API
- **엔드포인트**: `POST /api/events`
- **기능**: 웹사이트 이벤트 데이터 배치 수집 및 저장
- **인증**: X-API-Key 헤더
- **Rate Limit**: 1000 req/min
- **요청 형식**:
```json
{
  "events": [
    {
      "session_id": "uuid-v4",
      "timestamp": 1703123456789,
      "event_type": "page_view",
      "page_url": "https://example.com/page",
      "user_agent": "Mozilla/5.0...",
      "referrer": "https://google.com"
    }
  ]
}
```
- **응답 형식**:
```json
{
  "status": "success",
  "data": {
    "processed_events": 1,
    "session_updated": true,
    "new_session": false
  }
}
```
- **배치 처리**: 최대 100개 이벤트/요청
- **TTL**: 24시간 자동 삭제

### 2. 실시간 데이터 API
- **엔드포인트**: `GET /api/realtime`
- **기능**: 현재 활성 사용자 및 실시간 통계 제공 (HTMX 호환)
- **캐시**: 3초 (폴링 간격)
- **응답 형식 (JSON)**:
```json
{
  "status": "success",
  "data": {
    "active_users": 42,
    "current_pages": {
      "/": 15,
      "/products": 12,
      "/about": 8
    },
    "events_last_5min": 156,
    "timestamp": 1703123456789
  }
}
```
- **응답 형식 (HTML - HTMX용)**:
```html
<div class="realtime-stats">
  <div class="active-users">42</div>
  <div class="page-list">...</div>
</div>
```

### 3. 통계 데이터 API
- **엔드포인트**: `GET /api/stats`
- **기능**: 시간대별 방문자 통계 및 페이지 분석 (Chart.js 호환)
- **쿼리 파라미터**: 
  - `period`: hour, day (기본값: hour)
  - `limit`: 결과 개수 (기본값: 24)
- **캐시**: 30초
- **응답 형식**:
```json
{
  "status": "success",
  "data": {
    "hourly_visitors": {
      "labels": ["00:00", "01:00", "02:00"],
      "data": [10, 15, 23]
    },
    "top_pages": [
      {"url": "/", "views": 150, "percentage": 45.2},
      {"url": "/products", "views": 89, "percentage": 26.8}
    ],
    "summary": {
      "total_sessions": 234,
      "total_pageviews": 456,
      "avg_session_duration": 180
    }
  }
}
```

## 데이터 모델 (Pydantic)

### Event 모델
```python
from pydantic import BaseModel, Field
from typing import Optional, Literal
import time

class Event(BaseModel):
    session_id: str = Field(..., min_length=1, max_length=100)
    timestamp: int = Field(..., gt=0)
    event_type: Literal["page_view", "session_start", "session_end"] = "page_view"
    page_url: str = Field(..., min_length=1, max_length=2048)
    user_agent: Optional[str] = Field(None, max_length=512)
    referrer: Optional[str] = Field(None, max_length=2048)
    ttl: int = Field(default_factory=lambda: int(time.time()) + 86400)

class EventBatch(BaseModel):
    events: list[Event] = Field(..., min_items=1, max_items=100)
```

### Session 모델
```python
class Session(BaseModel):
    session_id: str = Field(..., min_length=1, max_length=100)
    start_time: int = Field(..., gt=0)
    last_activity: int = Field(..., gt=0)
    is_active: bool = True
    page_count: int = Field(default=1, ge=0)
    referrer: Optional[str] = Field(None, max_length=2048)
    user_agent: Optional[str] = Field(None, max_length=512)
    ttl: int = Field(default_factory=lambda: int(time.time()) + 86400)

    def update_activity(self, timestamp: int) -> None:
        self.last_activity = timestamp
        self.page_count += 1
        
    def is_expired(self, current_time: int, timeout: int = 1800) -> bool:
        return (current_time - self.last_activity) > timeout
```

## DynamoDB 테이블 구조

### Events 테이블 (liveinsight-events-dev)
```
PK: session_id (String)
SK: timestamp (Number)
Attributes:
- event_type: String (page_view, session_start, session_end)
- page_url: String
- user_agent: String (Optional)
- referrer: String (Optional)
- ttl: Number (24시간 후 자동 삭제)

GSI: EventTypeIndex
- PK: event_type
- SK: timestamp
- 용도: 이벤트 타입별 시간순 조회
```

### Sessions 테이블 (liveinsight-sessions-dev)
```
PK: session_id (String)
Attributes:
- start_time: Number
- last_activity: Number
- is_active: Boolean
- page_count: Number
- referrer: String (Optional)
- user_agent: String (Optional)
- ttl: Number (24시간 후 자동 삭제)

GSI: ActivityIndex
- PK: is_active (Boolean)
- SK: last_activity (Number)
- 용도: 활성 세션 조회 및 실시간 통계
```

## 비즈니스 로직

### 세션 관리 로직
```python
def process_session(session_id: str, timestamp: int) -> Session:
    # 1. 기존 세션 조회
    session = get_session(session_id)
    
    if not session:
        # 2. 새 세션 생성
        session = Session(
            session_id=session_id,
            start_time=timestamp,
            last_activity=timestamp,
            is_active=True,
            page_count=1
        )
    else:
        # 3. 세션 업데이트
        if session.is_expired(timestamp, timeout=1800):  # 30분
            session.is_active = False
        else:
            session.update_activity(timestamp)
    
    return session
```

### 실시간 데이터 처리
```python
def get_realtime_stats() -> dict:
    current_time = int(time.time())
    five_min_ago = current_time - 300
    
    # 1. 활성 사용자 (30분 내 활동)
    active_users = count_active_sessions(current_time - 1800)
    
    # 2. 최근 5분 이벤트
    recent_events = get_events_since(five_min_ago)
    
    # 3. 페이지별 현재 방문자
    current_pages = aggregate_current_pages(recent_events)
    
    return {
        "active_users": active_users,
        "current_pages": current_pages,
        "events_last_5min": len(recent_events)
    }
```

### 통계 집계 로직
```python
def get_hourly_stats(hours: int = 24) -> dict:
    end_time = int(time.time())
    start_time = end_time - (hours * 3600)
    
    # 시간대별 이벤트 집계
    hourly_data = []
    for i in range(hours):
        hour_start = start_time + (i * 3600)
        hour_end = hour_start + 3600
        count = count_events_in_range(hour_start, hour_end)
        hourly_data.append(count)
    
    return {
        "labels": generate_hour_labels(hours),
        "data": hourly_data
    }
```

## 성능 요구사항
- **이벤트 수집 API**: < 100ms (P95)
- **실시간 API**: < 200ms (P95)
- **통계 API**: < 500ms (P95)
- **동시 처리**: 1000 req/min (API Gateway Rate Limit)
- **배치 크기**: 최대 100개 이벤트/요청
- **데이터 보존**: 24시간 (DynamoDB TTL)
- **Lambda 메모리**: 256MB (비용 최적화)
- **Lambda 타임아웃**: 30초

## 에러 처리 및 응답 코드
```python
# HTTP 상태 코드
200: 성공
400: 잘못된 요청 (Pydantic 검증 실패)
401: 인증 실패 (API Key 없음/잘못됨)
429: 요청 제한 초과 (Rate Limiting)
500: 서버 내부 오류 (DynamoDB 연결 실패 등)

# 에러 응답 형식
{
  "status": "error",
  "message": "Invalid event data",
  "details": {
    "field": "timestamp",
    "error": "must be greater than 0"
  }
}
```

## 로깅 및 모니터링
```python
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# 로깅 규칙
logger.info(f"Processing {len(events)} events for session {session_id}")
logger.error(f"DynamoDB error: {str(e)}", extra={"session_id": session_id})
logger.warning(f"Session expired: {session_id}")

# 성능 메트릭
start_time = time.time()
# ... 비즈니스 로직 ...
processing_time = time.time() - start_time
logger.info(f"Request processed in {processing_time:.3f}s")
```

## Lambda 최적화
```python
# 글로벌 변수로 연결 재사용 (콜드 스타트 최적화)
import boto3
import os

dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])
sessions_table = dynamodb.Table(os.environ['SESSIONS_TABLE'])

# 배치 쓰기로 성능 향상
def batch_write_events(events: list[Event]):
    with events_table.batch_writer() as batch:
        for event in events:
            batch.put_item(Item=event.dict())
```

## 환경 변수
```python
# Lambda 환경 변수
EVENTS_TABLE = os.environ['EVENTS_TABLE']        # liveinsight-events-dev
SESSIONS_TABLE = os.environ['SESSIONS_TABLE']    # liveinsight-sessions-dev
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
API_KEY = os.environ.get('API_KEY', 'dev-api-key-12345')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
```

## 보안 고려사항
- **API Key 검증**: X-API-Key 헤더 필수
- **CORS 설정**: 허용된 도메인만 접근
- **IP 마스킹**: 개인정보 보호 (마지막 옥텟 마스킹)
- **데이터 최소화**: 필요한 데이터만 수집
- **HTTPS 강제**: 모든 통신 암호화
- **Rate Limiting**: DDoS 공격 방지

## 테스트 전략
```python
# 단위 테스트 (pytest)
def test_event_validation():
    event = Event(
        session_id="test-session",
        timestamp=1703123456789,
        event_type="page_view",
        page_url="https://example.com"
    )
    assert event.session_id == "test-session"

# API 테스트
def test_event_collection_api():
    response = client.post("/api/events", 
        json={"events": [test_event_data]},
        headers={"X-API-Key": "test-key"}
    )
    assert response.status_code == 200
```