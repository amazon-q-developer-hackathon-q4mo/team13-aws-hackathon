# 담당자 B - 백엔드 개발 가이드

## 담당 영역
- Python Lambda 함수 개발
- 비즈니스 로직 구현
- 데이터 모델 설계
- API 엔드포인트 구현

## 작업 디렉토리
- `src/` - 모든 Python 소스코드
- `static/` - 대시보드 HTML/JS (공통)

## 소스코드 구조
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
└── utils/
    ├── response.py           # HTTP 응답 헬퍼
    └── validation.py         # 데이터 검증
```

## Lambda 핸들러 템플릿
```python
from fastapi import FastAPI
from mangum import Mangum
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = FastAPI()

@app.post("/api/events")
async def collect_events(events: EventBatch):
    try:
        # 비즈니스 로직
        return {"status": "success"}
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500)

handler = Mangum(app)
```

## 데이터 모델 (Pydantic)
```python
from pydantic import BaseModel
from typing import List, Optional
import time

class Event(BaseModel):
    session_id: str
    timestamp: int
    event_type: str
    page_url: str
    user_agent: Optional[str] = None
    referrer: Optional[str] = None
    ttl: int = int(time.time()) + 86400
```

## DynamoDB 연동
```python
import boto3
import os

# 글로벌 변수로 연결 재사용
dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])
sessions_table = dynamodb.Table(os.environ['SESSIONS_TABLE'])
```

## API 응답 형식
```python
# 성공 응답
{"status": "success", "data": {...}}

# 에러 응답
{"status": "error", "message": "Error description"}
```

## 실시간 데이터 처리
- 활성 세션 조회 (is_active=true)
- 최근 5분 이벤트 집계
- 페이지별 현재 방문자 수

## 세션 관리 로직
- 세션 생성: 첫 페이지뷰 시
- 세션 업데이트: 매 이벤트마다 last_activity
- 세션 만료: 30분 비활성 시 is_active=false

## 성능 최적화
- DynamoDB 배치 쓰기 사용
- 연결 풀링으로 콜드 스타트 최소화
- 불필요한 데이터 조회 방지

## 에러 처리
```python
try:
    # 비즈니스 로직
except ClientError as e:
    logger.error(f"DynamoDB error: {e}")
    raise HTTPException(status_code=500)
except ValidationError as e:
    logger.error(f"Validation error: {e}")
    raise HTTPException(status_code=400)
```

## 로깅 규칙
```python
logger.info(f"Processing {len(events)} events")
logger.error(f"Failed to process event: {event_id}")
```

## 테스트 코드
```python
def test_event_validation():
    event = Event(
        session_id="test",
        timestamp=1234567890,
        event_type="page_view",
        page_url="https://example.com"
    )
    assert event.session_id == "test"
```

## 주의사항
- 담당자 A의 인프라 변경 시 환경변수 확인
- DynamoDB 테이블명은 환경변수에서 가져오기
- API 스키마 변경 시 문서 업데이트