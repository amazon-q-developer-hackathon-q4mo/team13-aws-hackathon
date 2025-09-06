# E-commerce 시나리오 테스트

## 개요

이 테스트는 **시나리오 1: E-commerce 웹사이트 운영자 (김대리)**의 하루 업무 흐름을 시뮬레이션합니다.

## 테스트 시나리오

### 김대리의 하루 업무 흐름

#### 1. 아침 업무 시작 (09:00)
- 대시보드 접속하여 실시간 지표 확인
- 현재 활성 사용자 수, 총 이벤트 수, 평균 세션 시간, 전환율 확인

#### 2. 실시간 모니터링 (10:30)
- 시간대별 트래픽 차트에서 급격한 증가 발견
- 특정 상품 페이지로 트래픽 집중 확인
- 마케팅팀에 프로모션 효과 공유

#### 3. 점심시간 트래픽 분석 (12:00)
- 유입경로 파이차트 확인
- SNS 유입이 평소보다 높음을 발견
- SNS 마케팅 캠페인 효과 확인

#### 4. 오후 성과 분석 (15:00)
- 페이지별 통계에서 장바구니 페이지 이탈률 높음 발견
- 해당 페이지 상세 분석
- 개발팀에 페이지 개선 요청

#### 5. 활성 세션 모니터링 (지속적)
- 실시간 활성 세션 목록 확인
- 각 세션의 현재 페이지와 지속 시간 모니터링

## 테스트 구조

```
tests/scenarios/
├── test_ecommerce_scenario.py    # 메인 테스트 케이스
├── test_runner.py                # 테스트 실행기
├── conftest.py                   # pytest 설정
└── README.md                     # 이 문서
```

## 실행 방법

### 1. 전제 조건
```bash
# Django 서버 실행
cd src
python manage.py runserver

# 필요한 패키지 설치
pip install pytest requests
```

### 2. 테스트 실행

#### 방법 1: 테스트 실행기 사용 (권장)
```bash
cd tests/scenarios
python test_runner.py
```

#### 방법 2: pytest 직접 실행
```bash
cd tests/scenarios
pytest test_ecommerce_scenario.py -v
```

#### 방법 3: 개별 테스트 실행
```bash
cd tests/scenarios
python test_ecommerce_scenario.py
```

### 3. 특정 테스트만 실행
```bash
# 아침 대시보드 체크만 실행
pytest test_ecommerce_scenario.py::TestEcommerceScenario::test_morning_dashboard_check -v

# 통합 테스트만 실행
pytest test_ecommerce_scenario.py::TestEcommerceScenarioIntegration -v
```

## 테스트 케이스 상세

### TestEcommerceScenario 클래스

| 테스트 메소드 | 설명 | 검증 항목 |
|--------------|------|-----------|
| `test_morning_dashboard_check` | 아침 대시보드 확인 | 요약 통계 API 응답 및 데이터 구조 |
| `test_realtime_traffic_monitoring` | 실시간 트래픽 모니터링 | 시간대별/페이지별 통계 API |
| `test_lunch_traffic_analysis` | 점심시간 유입경로 분석 | 유입경로 통계 API 및 데이터 분석 |
| `test_afternoon_performance_analysis` | 오후 성과 분석 | 페이지 상세 분석 API |
| `test_active_sessions_monitoring` | 활성 세션 모니터링 | 활성 세션 API 및 세션 데이터 |

### TestEcommerceScenarioIntegration 클래스

| 테스트 메소드 | 설명 | 검증 항목 |
|--------------|------|-----------|
| `test_full_day_workflow` | 하루 전체 워크플로우 | 모든 API 엔드포인트 순차 실행 |

## API 엔드포인트 테스트

### 테스트되는 API 목록

1. **GET /api/statistics/summary/**
   - 전체 요약 통계
   - 응답 필드: `total_sessions`, `total_events`, `avg_session_time`, `conversion_rate`

2. **GET /api/statistics/hourly/**
   - 시간대별 이벤트 통계
   - 응답 형식: `[{"hour": "14:30", "count": 45}, ...]`

3. **GET /api/statistics/pages/**
   - 페이지별 조회 통계
   - 응답 형식: `[{"page": "/home", "views": 1234}, ...]`

4. **GET /api/statistics/referrers/**
   - 유입경로별 통계
   - 응답 형식: `{"labels": [...], "data": [...]}`

5. **GET /api/sessions/active/**
   - 현재 활성 세션 목록
   - 응답 필드: `session_id`, `user_id`, `current_page`, `duration`

6. **GET /api/dashboard/page-details/**
   - 특정 페이지 상세 분석
   - 쿼리 파라미터: `page` (페이지 URL)

## 검증 항목

### 1. API 응답 검증
- HTTP 상태 코드 200 확인
- 응답 데이터 JSON 형식 검증
- 필수 필드 존재 확인

### 2. 데이터 구조 검증
- 배열/객체 타입 확인
- 필드 데이터 타입 검증
- 빈 데이터 처리 확인

### 3. 비즈니스 로직 검증
- 시간대별 데이터 순서 확인
- 통계 데이터 합계 검증
- 세션 지속 시간 계산 확인

## 예상 결과

### 성공 시 출력 예시
```
🧪 E-commerce 시나리오 테스트 시작

🌅 테스트: 아침 업무 시작 (09:00)
✅ 현재 활성 사용자: 47
✅ 총 이벤트 수: 1,234
✅ 평균 세션 시간: 2분 30초
✅ 전환율: 3.2%

📈 테스트: 실시간 트래픽 모니터링 (10:30)
✅ 최근 시간대 (14:30) 이벤트 수: 45
✅ 최고 조회 페이지: /home (856회)

🍽️ 테스트: 점심시간 유입경로 분석 (12:00)
✅ 유입경로별 통계:
   Direct: 45명 (50.0%)
   Google: 32명 (35.6%)
   Facebook: 13명 (14.4%)

📊 테스트: 오후 성과 분석 (15:00)
⚠️ 해당 페이지 데이터 없음 (정상적인 경우)

👥 테스트: 활성 세션 모니터링
✅ 현재 활성 세션 수: 3
   세션 sess_1701234567_abc... - /products/item1 (5분)

🏢 통합 테스트: 김대리의 하루 업무 흐름
✅ 1단계: 아침 대시보드 체크 완료
✅ 2단계: 실시간 모니터링 완료
✅ 3단계: 유입경로 분석 완료
✅ 4단계: 페이지 성과 분석 완료
✅ 5단계: 활성 세션 모니터링 완료
🎉 김대리의 하루 업무 흐름 테스트 완료!

🎉 모든 테스트 완료!
```

## 문제 해결

### 1. 서버 연결 실패
```
❌ Django 서버가 실행되지 않았습니다.
💡 다음 명령어로 서버를 시작하세요:
   cd src && python manage.py runserver
```

### 2. 데이터 없음
- DynamoDB 테이블이 생성되어 있는지 확인
- 테스트 데이터가 있는지 확인
- `demo_website.html`로 테스트 이벤트 생성

### 3. 패키지 누락
```bash
pip install pytest requests boto3 django djangorestframework
```

## 확장 가능성

### 추가 테스트 시나리오
1. **마케팅 담당자 시나리오**: 캠페인 성과 측정
2. **개발자 시나리오**: 성능 분석 및 A/B 테스트
3. **콘텐츠 운영자 시나리오**: 콘텐츠 인기도 분석

### 성능 테스트
- API 응답 시간 측정
- 동시 요청 처리 능력
- 대용량 데이터 처리 성능

### 부하 테스트
- 다수 사용자 동시 접속 시뮬레이션
- 트래픽 급증 상황 테스트
- 시스템 한계점 측정