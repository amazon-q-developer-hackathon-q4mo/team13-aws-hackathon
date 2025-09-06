# LiveInsight API 명세서

## 📋 API 개요

LiveInsight는 실시간 웹 분석을 위한 RESTful API를 제공합니다. 모든 API는 JSON 형식으로 데이터를 주고받으며, CORS를 지원합니다.

**Base URL**: `https://your-domain.com/api/`

## 🔐 인증

현재 버전에서는 인증이 필요하지 않습니다. (향후 API Key 인증 예정)

## 📊 이벤트 수집 API

### POST /events
웹사이트에서 발생하는 사용자 이벤트를 수집합니다.

**Endpoint**: `POST https://api-gateway-url/events`

**Request Headers**:
```http
Content-Type: application/json
```

**Request Body**:
```json
{
  "user_id": "user_abc123",
  "session_id": "sess_20241201_abc123",
  "event_type": "page_view",
  "page_url": "https://example.com/products/item1",
  "referrer": "https://google.com",
  "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
  "timestamp": 1701432000000
}
```

**Response**:
```json
{
  "message": "Event processed successfully",
  "event_id": "evt_20241201_123456_abc123",
  "session_id": "sess_20241201_abc123"
}
```

**이벤트 타입**:
- `page_view`: 페이지 조회
- `click`: 요소 클릭
- `conversion`: 전환 이벤트
- `heartbeat`: 활성 상태 유지

## 📈 분석 API

### GET /api/sessions/active/
현재 활성 상태인 세션 목록을 조회합니다.

**Response**:
```json
[
  {
    "session_id": "sess_20241201_abc123",
    "user_id": "user_abc123",
    "last_activity": 1701433800000,
    "current_page": "/products/item1",
    "duration": 1800000
  }
]
```

**캐시**: 30초

### GET /api/sessions/{session_id}/events/
특정 세션의 모든 이벤트를 조회합니다.

**Parameters**:
- `session_id` (string): 세션 식별자

**Response**:
```json
[
  {
    "event_id": "evt_20241201_123456_abc123",
    "timestamp": 1701432000000,
    "event_type": "page_view",
    "page_url": "/home",
    "referrer": "https://google.com"
  },
  {
    "event_id": "evt_20241201_123457_abc124",
    "timestamp": 1701432030000,
    "event_type": "click",
    "page_url": "/home",
    "element_tag": "BUTTON"
  }
]
```

## 📊 통계 API

### GET /api/statistics/summary/
전체 요약 통계를 조회합니다.

**Response**:
```json
{
  "total_sessions": "1,234",
  "total_events": "12,345",
  "avg_session_time": "2분 30초",
  "conversion_rate": "3.2%"
}
```

### GET /api/statistics/hourly/
시간대별 이벤트 통계를 조회합니다.

**Query Parameters**:
- `hours` (integer, optional): 조회할 시간 범위 (기본값: 24)

**Response**:
```json
[
  {
    "hour": "14:00",
    "count": 45
  },
  {
    "hour": "14:05",
    "count": 52
  },
  {
    "hour": "14:10",
    "count": 38
  }
]
```

**특징**:
- 5분 단위로 집계
- 최근 100분간 20개 데이터 포인트 제공
- 한국 시간대 기준

### GET /api/statistics/pages/
페이지별 조회 통계를 조회합니다.

**Response**:
```json
[
  {
    "page": "/home",
    "views": 1234
  },
  {
    "page": "/products/item1",
    "views": 856
  },
  {
    "page": "/about",
    "views": 432
  }
]
```

### GET /api/statistics/referrers/
유입경로별 통계를 조회합니다.

**Response**:
```json
{
  "labels": ["Direct", "Google", "Facebook", "Twitter", "Other"],
  "data": [45, 32, 15, 8, 12]
}
```

## 🎯 대시보드 API

### GET /api/dashboard/hourly-details/
특정 시간대의 상세 이벤트를 조회합니다.

**Query Parameters**:
- `hour` (string, required): 시간대 (HH:MM 형식, 예: "14:30")

**Response**:
```json
{
  "hour": "14:30",
  "total_events": 25,
  "events": [
    {
      "event_id": "evt_20241201_143001_abc123",
      "user_id": "user_abc123",
      "session_id": "sess_20241201_abc123",
      "event_type": "page_view",
      "page_url": "/products/item1",
      "timestamp": 1701432600000,
      "formatted_time": "14:30:00"
    }
  ]
}
```

### GET /api/dashboard/page-details/
특정 페이지의 상세 통계를 조회합니다.

**Query Parameters**:
- `page` (string, required): 페이지 URL

**Response**:
```json
{
  "page_url": "/products/item1",
  "total_views": 156,
  "recent_events": [
    {
      "event_id": "evt_20241201_143001_abc123",
      "user_id": "user_abc123",
      "session_id": "sess_20241201_abc123",
      "timestamp": 1701432600000,
      "formatted_time": "14:30:00",
      "referrer": "https://google.com"
    }
  ],
  "hourly_distribution": {
    "13:00": 12,
    "14:00": 18,
    "15:00": 25
  }
}
```

### GET /api/dashboard/referrer-details/
특정 유입경로의 상세 통계를 조회합니다.

**Query Parameters**:
- `referrer` (string, required): 유입경로명

**Response**:
```json
{
  "referrer": "Google",
  "total_visitors": 234,
  "recent_visits": [
    {
      "event_id": "evt_20241201_143001_abc123",
      "user_id": "user_abc123",
      "session_id": "sess_20241201_abc123",
      "timestamp": 1701432600000,
      "formatted_time": "12/01 14:30",
      "landing_page": "/home"
    }
  ],
  "hourly_distribution": {
    "13:00": 15,
    "14:00": 22,
    "15:00": 18
  }
}
```

## 🚨 에러 응답

모든 API는 다음과 같은 형식으로 에러를 반환합니다:

```json
{
  "error": "Error message description"
}
```

**HTTP 상태 코드**:
- `200`: 성공
- `400`: 잘못된 요청
- `404`: 리소스를 찾을 수 없음
- `405`: 허용되지 않는 메소드
- `500`: 서버 내부 오류

## 📝 JavaScript SDK 사용법

### 초기화
```javascript
// SDK 초기화
LiveInsight.init({
    apiUrl: 'https://your-api-gateway-url/events'
});
```

### 이벤트 추적
```javascript
// 커스텀 이벤트 추적
LiveInsight.track('button_click', {
    button_name: 'signup',
    page_url: window.location.href
});

// 전환 이벤트 추적
LiveInsight.trackConversion('purchase');
```

### 자동 추적 이벤트
SDK는 다음 이벤트를 자동으로 추적합니다:
- 페이지 로드 시 `page_view`
- 버튼/링크 클릭 시 `click`
- 30초마다 `heartbeat`
- 페이지 이탈 시 `page_exit`

## 🔄 실시간 업데이트

대시보드는 다음 간격으로 자동 새로고침됩니다:
- 활성 세션: 30초
- 시간대별 통계: 30초
- 페이지별 통계: 30초
- 유입경로 통계: 30초
- 요약 통계: 30초

## 📊 데이터 보존 정책

- **Events**: 영구 보존
- **Sessions**: 영구 보존
- **ActiveSessions**: 30분 후 자동 삭제 (TTL)

## 🔒 보안 고려사항

1. **CORS**: 모든 도메인에서 접근 가능 (프로덕션에서는 제한 권장)
2. **Rate Limiting**: 현재 미적용 (향후 구현 예정)
3. **데이터 검증**: 서버 사이드에서 모든 입력 데이터 검증
4. **IP 추적**: 클라이언트 IP 자동 수집 및 저장

## 📈 성능 특성

- **응답 시간**: 평균 100ms 이하
- **처리량**: 초당 1000+ 이벤트 처리 가능
- **가용성**: 99.9% (서버리스 아키텍처)
- **확장성**: 자동 스케일링 지원