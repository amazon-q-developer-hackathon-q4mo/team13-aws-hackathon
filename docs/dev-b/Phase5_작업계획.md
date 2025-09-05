# Phase 5: 테스트 및 배포 (2시간) - 개발자 B

## 목표
통합 테스트, 데모 데이터 생성, UI/UX 최종 점검, 프레젠테이션 준비

## 작업 내용

### 1. 전체 시스템 통합 테스트 (45분)

**이벤트 수집 → 저장 → 조회 플로우 테스트**
```python
# tests/test_integration.py
import requests
import time
import json
from django.test import TestCase
from django.test.utils import override_settings

class IntegrationTestCase(TestCase):
    
    def setUp(self):
        self.api_url = "https://YOUR_API_GATEWAY_URL/events"
        self.dashboard_url = "http://localhost:8000"
    
    def test_event_collection_flow(self):
        """이벤트 수집부터 대시보드 표시까지 전체 플로우 테스트"""
        
        # 1. 이벤트 전송
        test_events = [
            {
                "user_id": "test_user_integration",
                "event_type": "page_view",
                "page_url": "https://example.com/home",
                "referrer": "https://google.com"
            },
            {
                "user_id": "test_user_integration",
                "event_type": "page_view",
                "page_url": "https://example.com/products"
            },
            {
                "user_id": "test_user_integration",
                "event_type": "conversion",
                "conversion_type": "purchase"
            }
        ]
        
        session_id = None
        for event_data in test_events:
            if session_id:
                event_data['session_id'] = session_id
            
            response = requests.post(self.api_url, json=event_data)
            self.assertEqual(response.status_code, 200)
            
            if not session_id:
                session_id = response.json().get('session_id')
        
        # 2. 데이터 전파 대기
        time.sleep(5)
        
        # 3. 대시보드에서 데이터 확인
        response = requests.get(f"{self.dashboard_url}/api/sessions/active/")
        self.assertEqual(response.status_code, 200)
        
        sessions = response.json()
        test_session = next((s for s in sessions if s['user_id'] == 'test_user_integration'), None)
        self.assertIsNotNone(test_session)
        
        # 4. 세션 이벤트 확인
        response = requests.get(f"{self.dashboard_url}/api/sessions/{session_id}/events/")
        self.assertEqual(response.status_code, 200)
        
        events = response.json()
        self.assertEqual(len(events), 3)
    
    def test_statistics_api(self):
        """통계 API 테스트"""
        endpoints = [
            "/api/statistics/hourly/",
            "/api/statistics/pages/"
        ]
        
        for endpoint in endpoints:
            response = requests.get(f"{self.dashboard_url}{endpoint}")
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertIsInstance(data, list)
```

**프론트엔드 기능 테스트**
```javascript
// static/js/test-suite.js
class FrontendTester {
    constructor() {
        this.tests = [];
        this.results = [];
    }
    
    addTest(name, testFn) {
        this.tests.push({ name, testFn });
    }
    
    async runTests() {
        console.log('Starting frontend tests...');
        
        for (const test of this.tests) {
            try {
                await test.testFn();
                this.results.push({ name: test.name, status: 'PASS' });
                console.log(`✓ ${test.name}`);
            } catch (error) {
                this.results.push({ name: test.name, status: 'FAIL', error: error.message });
                console.error(`✗ ${test.name}: ${error.message}`);
            }
        }
        
        this.printResults();
    }
    
    printResults() {
        const passed = this.results.filter(r => r.status === 'PASS').length;
        const total = this.results.length;
        console.log(`\nTest Results: ${passed}/${total} passed`);
    }
}

// 테스트 케이스들
const tester = new FrontendTester();

tester.addTest('Active Sessions Load', async () => {
    const response = await fetch('/api/sessions/active/');
    if (!response.ok) throw new Error('Failed to load active sessions');
    const data = await response.json();
    if (!Array.isArray(data)) throw new Error('Invalid response format');
});

tester.addTest('Chart Initialization', async () => {
    if (typeof Chart === 'undefined') throw new Error('Chart.js not loaded');
    if (!window.hourlyChart) throw new Error('Hourly chart not initialized');
    if (!window.pageChart) throw new Error('Page chart not initialized');
});

tester.addTest('LiveInsight Tracker', async () => {
    if (typeof LiveInsight === 'undefined') throw new Error('LiveInsight tracker not loaded');
    if (typeof LiveInsight.track !== 'function') throw new Error('Track function not available');
});

// 테스트 실행
// tester.runTests();
```

### 2. 데모 데이터 생성 및 시나리오 테스트 (45분)

**데모 데이터 생성 스크립트**
```python
# scripts/generate_demo_data.py
import requests
import random
import time
from datetime import datetime, timedelta
import uuid

class DemoDataGenerator:
    def __init__(self, api_url):
        self.api_url = api_url
        self.users = [f"demo_user_{i}" for i in range(1, 21)]  # 20명의 데모 사용자
        self.pages = [
            "https://example.com/",
            "https://example.com/products",
            "https://example.com/about",
            "https://example.com/contact",
            "https://example.com/pricing",
            "https://example.com/blog"
        ]
        self.referrers = [
            "https://google.com",
            "https://facebook.com",
            "https://twitter.com",
            "",  # Direct traffic
            "https://linkedin.com"
        ]
    
    def generate_user_session(self, user_id):
        """사용자 세션 시뮬레이션"""
        session_events = []
        session_id = f"demo_sess_{int(time.time())}_{user_id}"
        
        # 유입 이벤트
        entry_page = random.choice(self.pages)
        referrer = random.choice(self.referrers)
        
        session_events.append({
            "user_id": user_id,
            "session_id": session_id,
            "event_type": "page_view",
            "page_url": entry_page,
            "referrer": referrer
        })
        
        # 추가 페이지 조회 (1-5개)
        num_pages = random.randint(1, 5)
        current_page = entry_page
        
        for _ in range(num_pages):
            time.sleep(random.uniform(0.5, 2.0))  # 페이지 간 간격
            
            next_page = random.choice([p for p in self.pages if p != current_page])
            session_events.append({
                "user_id": user_id,
                "session_id": session_id,
                "event_type": "page_view",
                "page_url": next_page,
                "referrer": current_page
            })
            current_page = next_page
        
        # 전환 이벤트 (20% 확률)
        if random.random() < 0.2:
            session_events.append({
                "user_id": user_id,
                "session_id": session_id,
                "event_type": "conversion",
                "conversion_type": "signup",
                "page_url": current_page
            })
        
        return session_events
    
    def send_events(self, events):
        """이벤트 전송"""
        for event in events:
            try:
                response = requests.post(self.api_url, json=event)
                if response.status_code == 200:
                    print(f"✓ Sent: {event['event_type']} for {event['user_id']}")
                else:
                    print(f"✗ Failed: {response.status_code}")
            except Exception as e:
                print(f"✗ Error: {e}")
    
    def generate_historical_data(self, days=7):
        """과거 데이터 생성"""
        print(f"Generating {days} days of historical data...")
        
        for day in range(days):
            date = datetime.now() - timedelta(days=day)
            daily_sessions = random.randint(50, 150)
            
            print(f"Generating {daily_sessions} sessions for {date.strftime('%Y-%m-%d')}")
            
            for _ in range(daily_sessions):
                user_id = random.choice(self.users)
                events = self.generate_user_session(user_id)
                
                # 시간 조정 (해당 날짜로)
                for event in events:
                    random_hour = random.randint(0, 23)
                    random_minute = random.randint(0, 59)
                    event_time = date.replace(hour=random_hour, minute=random_minute)
                    event['timestamp'] = int(event_time.timestamp() * 1000)
                
                self.send_events(events)
                time.sleep(0.1)  # API 부하 방지
    
    def generate_realtime_data(self, duration_minutes=10):
        """실시간 데이터 생성"""
        print(f"Generating realtime data for {duration_minutes} minutes...")
        
        end_time = time.time() + (duration_minutes * 60)
        
        while time.time() < end_time:
            # 동시 사용자 시뮬레이션
            concurrent_users = random.randint(3, 8)
            
            for _ in range(concurrent_users):
                user_id = random.choice(self.users)
                events = self.generate_user_session(user_id)
                self.send_events(events)
            
            time.sleep(random.uniform(10, 30))  # 10-30초 간격

# 실행
if __name__ == "__main__":
    generator = DemoDataGenerator("https://YOUR_API_GATEWAY_URL/events")
    
    # 과거 데이터 생성
    generator.generate_historical_data(days=3)
    
    # 실시간 데이터 생성
    generator.generate_realtime_data(duration_minutes=5)
```

### 3. UI/UX 최종 점검 (15분)

**체크리스트**
```markdown
# UI/UX 점검 체크리스트

## 반응형 디자인
- [ ] 모바일 화면에서 정상 표시
- [ ] 태블릿 화면에서 정상 표시
- [ ] 데스크톱 화면에서 정상 표시

## 사용성
- [ ] 로딩 상태 표시
- [ ] 에러 메시지 표시
- [ ] 빈 데이터 상태 처리
- [ ] 버튼 클릭 피드백

## 성능
- [ ] 페이지 로딩 시간 < 3초
- [ ] 차트 렌더링 시간 < 2초
- [ ] API 응답 시간 < 1초

## 접근성
- [ ] 키보드 네비게이션 가능
- [ ] 색상 대비 적절
- [ ] 스크린 리더 호환

## 브라우저 호환성
- [ ] Chrome 최신 버전
- [ ] Firefox 최신 버전
- [ ] Safari 최신 버전
- [ ] Edge 최신 버전
```

### 4. 프레젠테이션 준비 (15분)

**데모 시나리오 스크립트**
```markdown
# LiveInsight 데모 시나리오

## 1. 프로젝트 소개 (2분)
- "실시간 웹사이트 사용자 행동 분석 서비스 LiveInsight를 소개합니다"
- 주요 기능: 실시간 모니터링, 통계 분석, 사용자 세션 추적

## 2. 실시간 모니터링 데모 (3분)
- 대시보드 메인 화면 시연
- 활성 세션 목록 표시
- 세션 상세 정보 모달 시연
- 실시간 업데이트 기능 시연

## 3. 통계 분석 데모 (3분)
- 통계 페이지 이동
- 시간대별 유입 차트 설명
- 페이지별 조회수 차트 설명
- 필터링 기능 시연

## 4. 기술 아키텍처 설명 (2분)
- AWS 서버리스 아키텍처
- DynamoDB + Lambda + API Gateway
- Django REST API + 프론트엔드

## 5. 질의응답 (5분)
- 기술적 질문 대응
- 확장성 및 성능 관련 질문
- 비즈니스 활용 방안
```

**발표 자료 구성**
```markdown
# 발표 슬라이드 구성

1. 제목 슬라이드
   - 팀명: Team13
   - 프로젝트명: LiveInsight
   - 팀원 소개

2. 문제 정의
   - 웹사이트 사용자 행동 분석의 필요성
   - 기존 솔루션의 한계

3. 솔루션 소개
   - LiveInsight 핵심 기능
   - 차별화 포인트

4. 기술 아키텍처
   - AWS 서버리스 아키텍처 다이어그램
   - 데이터 플로우

5. 데모 화면
   - 실시간 대시보드 스크린샷
   - 통계 차트 스크린샷

6. 개발 성과
   - 12시간 해커톤 성과
   - 구현된 기능 목록

7. 향후 계획
   - 추가 기능 개발 계획
   - 비즈니스 모델

8. 감사 인사
```

## 완료 기준
- [ ] 전체 시스템 통합 테스트 통과
- [ ] 데모 데이터 생성 및 검증
- [ ] UI/UX 체크리스트 완료
- [ ] 크로스 브라우저 테스트 완료
- [ ] 데모 시나리오 준비 완료
- [ ] 발표 자료 작성 완료