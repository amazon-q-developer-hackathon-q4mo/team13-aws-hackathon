# LiveInsight 연동 가이드

## 🚀 빠른 시작

### 1. 스크립트 추가
웹사이트의 `</head>` 태그 직전에 다음 코드를 추가하세요:

```html
<!-- LiveInsight 추적 스크립트 -->
<script src="https://d28t8gs7tn78ne.cloudfront.net/js/liveinsight.js"></script>
<script>
  LiveInsight.init('your-site-key');
</script>
```

### 2. 사이트 키 설정
`your-site-key`를 실제 사이트 식별자로 변경하세요:

```javascript
LiveInsight.init('my-awesome-website');
```

## 📊 기본 추적

### 자동 추적 이벤트
LiveInsight는 다음 이벤트를 자동으로 추적합니다:

- **페이지뷰**: 페이지 로드 및 SPA 라우팅
- **세션 시작/종료**: 사용자 세션 관리
- **페이지 가시성**: 탭 전환 추적

### 수집되는 데이터
```javascript
{
  "event_type": "page_view",
  "page_url": "https://example.com/page",
  "page_title": "페이지 제목",
  "referrer": "https://google.com",
  "user_agent": "Mozilla/5.0...",
  "timestamp": 1693900000000,
  "session_id": "uuid-session-id",
  "user_id": "uuid-user-id",
  "site_key": "your-site-key"
}
```

## 🎯 커스텀 이벤트 추적

### 기본 사용법
```javascript
// 단순 이벤트
LiveInsight.track('button_click');

// 속성이 있는 이벤트
LiveInsight.track('purchase', {
  product_id: 'prod-123',
  price: 29.99,
  currency: 'USD'
});
```

### 일반적인 이벤트 예시
```javascript
// 버튼 클릭
document.getElementById('cta-button').addEventListener('click', function() {
  LiveInsight.track('cta_click', {
    button_text: this.textContent,
    button_location: 'header'
  });
});

// 폼 제출
document.getElementById('contact-form').addEventListener('submit', function() {
  LiveInsight.track('form_submit', {
    form_type: 'contact',
    form_fields: ['name', 'email', 'message']
  });
});

// 스크롤 깊이
window.addEventListener('scroll', function() {
  var scrollPercent = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);
  if (scrollPercent >= 75) {
    LiveInsight.track('scroll_depth', {
      depth_percent: scrollPercent
    });
  }
});
```

## ⚙️ 고급 설정

### 초기화 옵션
```javascript
LiveInsight.init('your-site-key', {
  sessionTimeout: 30 * 60 * 1000,  // 30분 (기본값)
  retryAttempts: 3,                // 재시도 횟수
  retryDelay: 1000,                // 재시도 지연시간 (ms)
  batchSize: 10,                   // 배치 크기
  flushInterval: 5000              // 전송 간격 (ms)
});
```

### 세션 관리
```javascript
// 현재 세션 정보 확인 (개발자 도구에서)
console.log(localStorage.getItem('liveinsight_session'));

// 세션 강제 종료
LiveInsight.track('manual_logout');
LiveInsight.destroy();
```

## 🔧 SPA (Single Page Application) 지원

### React 예시
```javascript
// React Router와 함께 사용
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

function App() {
  const location = useLocation();

  useEffect(() => {
    // 라우트 변경 시 자동으로 페이지뷰 추적됨
    // 추가 작업 불필요
  }, [location]);

  return <div>...</div>;
}
```

### Vue.js 예시
```javascript
// Vue Router와 함께 사용
router.afterEach((to, from) => {
  // 자동으로 페이지뷰 추적됨
  // 추가 커스텀 이벤트 원하는 경우:
  LiveInsight.track('route_change', {
    from_path: from.path,
    to_path: to.path
  });
});
```

## 🛡️ 개인정보 보호

### 자동 IP 마스킹
LiveInsight는 개인정보 보호를 위해 다음을 수행합니다:

- IP 주소 마스킹 (마지막 옥텟 제거)
- 24시간 후 자동 데이터 삭제
- 쿠키 기반 식별 (개인정보 최소화)

### GDPR 준수
```javascript
// 사용자 동의 후 초기화
if (userConsent) {
  LiveInsight.init('your-site-key');
}

// 데이터 삭제 요청 시
LiveInsight.destroy();
localStorage.removeItem('liveinsight_user_id');
localStorage.removeItem('liveinsight_session');
```

## 🐛 디버깅

### 개발자 도구에서 확인
```javascript
// 브라우저 콘솔에서 실행
console.log('LiveInsight 상태:', {
  initialized: !!window.LiveInsight,
  sessionId: JSON.parse(localStorage.getItem('liveinsight_session') || '{}').sessionId,
  userId: localStorage.getItem('liveinsight_user_id')
});
```

### 네트워크 탭에서 확인
- API 호출: `POST /api/events`
- 응답 상태: `200 OK`
- 요청 본문: `{"events": [...]}`

## 📱 모바일 최적화

### 터치 이벤트 추적
```javascript
// 터치 이벤트
document.addEventListener('touchstart', function(e) {
  LiveInsight.track('touch_start', {
    element: e.target.tagName,
    x: e.touches[0].clientX,
    y: e.touches[0].clientY
  });
});
```

### 배터리 절약
LiveInsight는 다음을 통해 모바일 성능을 최적화합니다:

- 배치 처리로 네트워크 요청 최소화
- 페이지 숨김 시 이벤트 전송 중단
- 경량화된 스크립트 (압축 시 ~3KB)

## 🚨 문제 해결

### 일반적인 문제

#### 1. 이벤트가 전송되지 않음
```javascript
// 네트워크 연결 확인
fetch('https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/events', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ events: [{ test: true }] })
})
.then(response => console.log('API 응답:', response.status))
.catch(error => console.error('API 오류:', error));
```

#### 2. CORS 오류
CORS 오류가 발생하는 경우, 다음을 확인하세요:
- HTTPS 사용 여부
- 올바른 도메인에서 호출 여부

#### 3. localStorage 사용 불가
```javascript
// 시크릿 모드나 localStorage 비활성화 시에도 동작
// 임시 세션 ID로 대체됨
```

## 📞 지원

### 기술 지원
- **GitHub**: [team13-aws-hackathon](https://github.com/amazon-q-developer-hackathon-q4mo/team13-aws-hackathon)
- **문서**: [README.md](../docs/README.md)

### API 문서
- **엔드포인트**: `POST /api/events`
- **형식**: JSON
- **인증**: 없음 (개발 환경)

---

**🚀 LiveInsight로 실시간 웹 분석을 시작하세요!**