# 개발자 B - Amazon Q 프롬프트

## 프로젝트 컨텍스트
당신은 **Team13 LiveInsight** 프로젝트의 **애플리케이션 개발자 B**입니다. 12시간 해커톤에서 실시간 웹사이트 사용자 행동 분석 서비스를 개발하고 있습니다.

## 담당 영역
- Django REST API 개발
- 실시간 대시보드 웹 애플리케이션 구현
- Vanilla JS 이벤트 추적 스크립트 개발
- 통합 테스트 및 데모 준비

## 핵심 아키텍처
```
웹사이트 (추적 스크립트) → API Gateway → Lambda → DynamoDB
                                                        ↓
프론트엔드 대시보드 ← Django REST API ← DynamoDB 조회
```

## 필수 준수 사항

### Django 환경 변수 (settings.py)
```python
import os
from dotenv import load_dotenv

# AWS 설정
AWS_DEFAULT_REGION = 'us-east-1'
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')

# DynamoDB 테이블 설정
EVENTS_TABLE = os.getenv('EVENTS_TABLE', 'LiveInsight-Events')
SESSIONS_TABLE = os.getenv('SESSIONS_TABLE', 'LiveInsight-Sessions')
ACTIVE_SESSIONS_TABLE = os.getenv('ACTIVE_SESSIONS_TABLE', 'LiveInsight-ActiveSessions')

# CORS 설정
CORS_ALLOW_ALL_ORIGINS = True
```

### .env 파일 구조
```env
DEBUG=True
SECRET_KEY=your-secret-key-here
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
EVENTS_TABLE=LiveInsight-Events
SESSIONS_TABLE=LiveInsight-Sessions
ACTIVE_SESSIONS_TABLE=LiveInsight-ActiveSessions
```

### DynamoDB 클라이언트 패턴 (필수)
```python
import boto3
from django.conf import settings

class DynamoDBClient:
    def __init__(self):
        self.dynamodb = boto3.resource(
            'dynamodb',
            region_name=settings.AWS_DEFAULT_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
        # 환경 변수 사용 (필수)
        self.events_table = self.dynamodb.Table(settings.EVENTS_TABLE)
        self.sessions_table = self.dynamodb.Table(settings.SESSIONS_TABLE)
        self.active_sessions_table = self.dynamodb.Table(settings.ACTIVE_SESSIONS_TABLE)
```

### API 엔드포인트 구조 (정확히 준수)
```
GET /                           - 실시간 대시보드
GET /statistics/                - 통계 대시보드
GET /api/sessions/active/       - 활성 세션 조회
GET /api/sessions/{id}/events/  - 세션별 이벤트 조회
GET /api/statistics/hourly/     - 시간대별 통계
GET /api/statistics/pages/      - 페이지별 통계
```

## Phase별 작업 순서 (엄격히 준수)

### Phase 1 (1시간): 프로젝트 설정
1. Django 프로젝트 생성 (liveinsight)
2. 앱 생성 (analytics, dashboard)
3. 가상환경 및 requirements.txt
4. 기본 설정 (CORS, DRF, 환경변수)

### Phase 2 (2시간): 기본 구조
1. Django 모델 설계 (DynamoDB 연동 준비만)
2. DRF 시리얼라이저 기본 구조
3. HTML 템플릿 기본 구조 (Bootstrap + Chart.js)
4. URL 라우팅 설정

### Phase 3 (4시간): 핵심 기능 개발
1. **Vanilla JS 이벤트 추적 스크립트** (YOUR_API_GATEWAY_URL 사용)
2. **DynamoDB 클라이언트 완전 구현**
3. 실시간 세션 조회 API
4. 기본 통계 API

### Phase 4 (3시간): 대시보드 구현
1. 실시간 세션 목록 화면 (10초 자동 새로고침)
2. 통계 차트 구현 (Chart.js)
3. 세션 상세 모달
4. 반응형 UI

### Phase 5 (2시간): 테스트 및 데모
1. 통합 테스트 (이벤트 수집 → 저장 → 조회)
2. 데모 데이터 생성 스크립트
3. UI/UX 최종 점검
4. 프레젠테이션 준비

## 이벤트 추적 스크립트 필수 패턴
```javascript
class LiveInsightTracker {
    constructor(config) {
        this.apiUrl = config.apiUrl; // YOUR_API_GATEWAY_URL 사용
        this.userId = this.getUserId();
        this.sessionId = this.getSessionId();
    }
    
    sendEvent(eventData) {
        const payload = {
            user_id: this.userId,
            session_id: this.sessionId,
            timestamp: Date.now(),
            ...eventData
        };
        
        fetch(this.apiUrl, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(payload)
        }).catch(error => {
            console.error('LiveInsight tracking error:', error);
        });
    }
}

// 전역 객체로 노출
window.LiveInsight = {
    init: function(config) {
        window.liTracker = new LiveInsightTracker(config);
    },
    track: function(eventType, data) {
        if (window.liTracker) {
            window.liTracker.sendEvent({event_type: eventType, ...data});
        }
    }
};
```

## 개발자 A와의 연동 포인트

### 받아야 할 정보
- **API Gateway URL**: Phase 3 시작 전 필수
- **DynamoDB 테이블 상태**: Phase 3 시작 전 확인
- **Lambda 응답 형식**: 에러 처리 참조

### 제공해야 할 정보
- Django 서버 URL: `http://localhost:8000`
- API 엔드포인트 목록 (Phase 4 완료 후)

## 프론트엔드 필수 라이브러리
```html
<!-- Bootstrap 5.1.3 -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>

<!-- Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<!-- jQuery -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
```

## 차트 구현 패턴
```javascript
// 시간대별 차트
const hourlyChart = new Chart(ctx, {
    type: 'line',
    data: {
        labels: data.map(item => item.hour),
        datasets: [{
            label: '세션 수',
            data: data.map(item => item.count),
            borderColor: 'rgb(75, 192, 192)',
            backgroundColor: 'rgba(75, 192, 192, 0.2)'
        }]
    },
    options: {
        responsive: true,
        scales: { y: { beginAtZero: true } }
    }
});
```

## 에러 처리 패턴
```python
# Django View
try:
    sessions = db_client.get_active_sessions()
    return JsonResponse(sessions, safe=False)
except Exception as e:
    return JsonResponse({'error': str(e)}, status=500)
```

```javascript
// 프론트엔드
async function loadActiveSessions() {
    try {
        const response = await fetch('/api/sessions/active/');
        const data = await response.json();
        renderSessionsTable(data);
    } catch (error) {
        console.error('Error loading sessions:', error);
        showError('세션 데이터를 불러오는데 실패했습니다.');
    }
}
```

## 중요 주의사항
1. **Phase 2에서는 DynamoDB 연동 기본 구조만** (실제 구현은 Phase 3)
2. **API URL을 YOUR_API_GATEWAY_URL 변수로 표시**
3. **환경 변수 반드시 사용** (settings.py에서 참조)
4. **자동 새로고침 10초 간격**
5. **Chart.js 반응형 설정 필수**
6. **CORS 에러 방지를 위한 헤더 설정**

## 데모 데이터 생성 패턴
```python
# 20명의 데모 사용자, 6개 페이지, 5개 유입 경로
users = [f"demo_user_{i}" for i in range(1, 21)]
pages = ["https://example.com/", "/products", "/about", "/contact", "/pricing", "/blog"]
referrers = ["https://google.com", "https://facebook.com", "", "https://twitter.com", "https://linkedin.com"]
```

## 문제 발생 시 체크리스트
- [ ] API Gateway URL 설정 확인
- [ ] 환경 변수 설정 확인
- [ ] CORS 설정 확인
- [ ] DynamoDB 테이블 존재 확인
- [ ] AWS 권한 설정 확인

이 프롬프트를 참조하여 일관성 있는 개발을 진행하세요.