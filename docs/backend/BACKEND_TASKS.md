# 담당자 B - 백엔드 개발 Task 리스트 (24시간 해커톤)

## 전체 개발 일정 (24시간)

### Phase 1: 프로젝트 설정 (0-2시간)
### Phase 2: 데이터 모델 및 서비스 (2-6시간)  
### Phase 3: API 핸들러 구현 (6-12시간)
### Phase 4: 통합 및 최적화 (12-18시간)
### Phase 5: 테스트 및 배포 준비 (18-24시간)

---

## Phase 1: 프로젝트 설정 및 기본 구조 (0-2시간)

### Task 1.1: 프로젝트 초기화 (30분)
- [ ] uv 프로젝트 초기화
```bash
cd /Users/suin/Desktop/team13-aws-hackathon
uv init --name liveinsight-backend
```
- [ ] pyproject.toml 설정 확인 및 수정
- [ ] 필수 패키지 설치:
```bash
uv add fastapi mangum boto3 pydantic python-multipart
uv add --dev pytest pytest-asyncio black isort mypy
```

### Task 1.2: 디렉토리 구조 생성 (30분)
- [ ] `src/` 디렉토리 및 하위 구조 생성
```bash
mkdir -p src/{handlers,models,services,utils}
touch src/{__init__.py,main.py}
touch src/handlers/{__init__.py,event_collector.py,realtime_api.py,stats_api.py}
touch src/models/{__init__.py,events.py,sessions.py}
touch src/services/{__init__.py,dynamodb.py,analytics.py}
touch src/utils/{__init__.py,response.py,validation.py}
```

### Task 1.3: 기본 FastAPI 앱 설정 (60분)
- [ ] `src/main.py` - 메인 FastAPI 애플리케이션 구조
- [ ] CORS 설정 및 기본 미들웨어
- [ ] 환경변수 처리 로직
- [ ] Mangum 핸들러 설정

---

## Phase 2: 데이터 모델 및 서비스 (2-6시간)

### Task 2.1: Pydantic 모델 정의 (90분)
- [ ] `src/models/events.py` - Event, EventBatch 모델
  - session_id, timestamp, event_type, page_url 필드
  - Pydantic 검증 규칙 (Field 사용)
  - TTL 자동 설정 로직
- [ ] `src/models/sessions.py` - Session 모델
  - session_id, start_time, last_activity, is_active 필드
  - update_activity(), is_expired() 메서드
- [ ] `src/models/__init__.py` - 모델 export

### Task 2.2: DynamoDB 서비스 구현 (120분)
- [ ] `src/services/dynamodb.py` - DynamoDB 클라이언트 설정
  - 글로벌 변수로 연결 재사용 (콜드 스타트 최적화)
  - Events 테이블 CRUD 함수
  - Sessions 테이블 CRUD 함수
  - 배치 쓰기 함수 (batch_writer 사용)
  - 에러 처리 (ClientError, ValidationError)

### Task 2.3: 유틸리티 함수 구현 (60분)
- [ ] `src/utils/response.py` - HTTP 응답 헬퍼
  - success_response(), error_response() 함수
  - 표준 응답 형식 구현
- [ ] `src/utils/validation.py` - 데이터 검증 함수
  - API Key 검증
  - 세션 ID 형식 검증
  - URL 검증 함수

---

## Phase 3: API 핸들러 구현 (6-12시간)

### Task 3.1: 이벤트 수집 API (150분)
- [ ] `src/handlers/event_collector.py` 구현
  - POST /api/events 엔드포인트
  - EventBatch 모델 사용한 요청 검증
  - API Key 인증 미들웨어
  - 이벤트 배치 처리 로직 (최대 100개)
  - 세션 생성/업데이트 로직
  - DynamoDB 배치 쓰기
  - 에러 처리 및 로깅

### Task 3.2: 실시간 데이터 API (120분)
- [ ] `src/services/analytics.py` - 분석 로직 구현
  - get_active_sessions() - 활성 세션 조회
  - get_recent_events() - 최근 5분 이벤트
  - aggregate_current_pages() - 페이지별 방문자 집계
- [ ] `src/handlers/realtime_api.py` 구현
  - GET /api/realtime 엔드포인트
  - JSON/HTML 응답 형식 지원 (Accept 헤더 기반)
  - 3초 캐시 구현
  - 실시간 통계 계산

### Task 3.3: 통계 데이터 API (120분)
- [ ] `src/services/analytics.py` - 통계 로직 추가
  - get_hourly_stats() - 시간대별 통계
  - get_top_pages() - 인기 페이지 순위
  - calculate_summary() - 요약 통계
- [ ] `src/handlers/stats_api.py` 구현
  - GET /api/stats 엔드포인트
  - 쿼리 파라미터 처리 (period, limit)
  - Chart.js 호환 데이터 형식
  - 30초 캐시 구현

---

## Phase 4: 통합 및 최적화 (12-18시간)

### Task 4.1: FastAPI 앱 통합 (90분)
- [ ] `src/main.py` - 모든 라우터 등록
  - 이벤트 수집, 실시간, 통계 라우터 추가
  - 전역 예외 처리기
  - 로깅 미들웨어
  - 헬스체크 엔드포인트 (/health)

### Task 4.2: 성능 최적화 (120분)
- [ ] DynamoDB 쿼리 최적화
  - GSI 활용한 효율적 쿼리
  - 배치 처리 크기 조정
  - 불필요한 속성 제외 (ProjectionExpression)
- [ ] Lambda 메모리 및 타임아웃 최적화
- [ ] 응답 압축 및 캐싱 구현

### Task 4.3: 에러 처리 강화 (90분)
- [ ] 전역 예외 처리기 구현
- [ ] 상세한 에러 메시지 및 로깅
- [ ] Rate Limiting 구현 (API Gateway 연동)
- [ ] 재시도 로직 (DynamoDB 연결 실패 시)

---

## Phase 5: 테스트 및 배포 준비 (18-24시간)

### Task 5.1: 단위 테스트 작성 (120분)
- [ ] `tests/` 디렉토리 생성
- [ ] `tests/test_models.py` - 모델 검증 테스트
- [ ] `tests/test_services.py` - DynamoDB 서비스 테스트
- [ ] `tests/test_handlers.py` - API 엔드포인트 테스트
- [ ] pytest 실행 및 커버리지 확인

### Task 5.2: 로컬 테스트 및 검증 (90분)
- [ ] 로컬 DynamoDB 설정 (DynamoDB Local)
- [ ] FastAPI 개발 서버 실행
- [ ] API 엔드포인트 수동 테스트 (curl/Postman)
- [ ] 응답 형식 및 성능 확인

### Task 5.3: 배포 준비 (90분)
- [ ] Lambda 배포 패키지 생성 스크립트
- [ ] 환경변수 설정 문서화
- [ ] 담당자 A와 통합 테스트 준비
- [ ] API 문서 생성 (FastAPI 자동 문서화)

---

## 우선순위별 Task 분류

### 🔴 필수 (Core MVP) - 12시간
**목표**: 기본 동작하는 API 완성
1. **Task 1.1-1.3**: 프로젝트 설정 (2시간)
2. **Task 2.1**: 데이터 모델 (1.5시간)
3. **Task 2.2**: DynamoDB 서비스 기본 (2시간)
4. **Task 3.1**: 이벤트 수집 API (2.5시간)
5. **Task 3.2**: 실시간 API 기본 (2시간)
6. **Task 4.1**: FastAPI 통합 (1.5시간)
7. **Task 5.2**: 기본 테스트 (0.5시간)

### 🟡 중요 (Enhanced MVP) - 6시간
**목표**: 실용적인 분석 기능 추가
1. **Task 2.3**: 유틸리티 함수 (1시간)
2. **Task 3.3**: 통계 API (2시간)
3. **Task 4.2**: 성능 최적화 (2시간)
4. **Task 4.3**: 에러 처리 (1시간)

### 🟢 선택 (Polish) - 6시간
**목표**: 품질 향상 및 안정성
1. **Task 5.1**: 단위 테스트 (2시간)
2. **Task 5.3**: 배포 최적화 (1.5시간)
3. **추가 기능**: 고급 분석, 캐싱 개선 (2.5시간)

---

## 체크포인트 및 마일스톤

### 🕐 2시간 체크포인트
- [ ] 프로젝트 구조 완성
- [ ] FastAPI 기본 앱 실행 가능
- [ ] 기본 모델 정의 완료

### 🕕 6시간 체크포인트  
- [ ] 데이터 모델 및 DynamoDB 서비스 완성
- [ ] 이벤트 수집 API 기본 동작
- [ ] 로컬 테스트 환경 구축

### 🕘 12시간 체크포인트
- [ ] 모든 API 엔드포인트 구현 완료
- [ ] 실시간 데이터 조회 가능
- [ ] 기본 에러 처리 구현

### 🕒 18시간 체크포인트
- [ ] 성능 최적화 완료
- [ ] 통합 테스트 통과
- [ ] 담당자 A와 연동 준비

### 🕕 24시간 최종 체크포인트
- [ ] 전체 기능 동작 확인
- [ ] 배포 패키지 준비 완료
- [ ] 데모 시연 가능

---

## 개발 환경 설정

### 로컬 개발 명령어
```bash
# 개발 서버 실행
cd src && uvicorn main:app --reload --port 8000

# 테스트 실행
uv run pytest tests/ -v

# 코드 포맷팅
uv run black src/ tests/
uv run isort src/ tests/

# 타입 체크
uv run mypy src/
```

### 환경변수 설정 (.env)
```bash
EVENTS_TABLE=liveinsight-events-dev
SESSIONS_TABLE=liveinsight-sessions-dev
AWS_REGION=us-east-1
API_KEY=dev-api-key-12345
ENVIRONMENT=dev
```

---

## 위험 요소 및 대응 방안

### 🚨 고위험
- **DynamoDB 연결 실패**: 로컬 DynamoDB 우선 개발, 재시도 로직 구현
- **Lambda 콜드 스타트**: 글로벌 변수 활용, 메모리 최적화
- **API 성능 이슈**: 배치 처리, 캐싱, 쿼리 최적화

### ⚠️ 중위험  
- **Pydantic 검증 오류**: 단계적 검증 규칙 추가
- **HTMX 호환성**: JSON 우선 개발 후 HTML 응답 추가
- **시간 부족**: 필수 기능 우선, 선택 기능 제외

### ℹ️ 저위험
- **테스트 커버리지**: 핵심 로직 우선 테스트
- **문서화**: 코드 주석으로 대체
- **보안 강화**: 기본 API Key 인증으로 시작

---

## 성공 기준

### 최소 성공 기준 (12시간)
- [ ] 이벤트 수집 API 동작
- [ ] 실시간 접속자 수 조회 가능
- [ ] DynamoDB 데이터 저장/조회 정상

### 목표 성공 기준 (18시간)
- [ ] 모든 API 엔드포인트 완성
- [ ] 실시간 대시보드 데이터 제공
- [ ] 기본 통계 및 차트 데이터 제공

### 이상적 성공 기준 (24시간)
- [ ] 성능 최적화 완료 (응답시간 < 200ms)
- [ ] 에러 처리 및 로깅 완비
- [ ] 단위 테스트 80% 이상 커버리지
- [ ] 담당자 A와 완전 통합 완료