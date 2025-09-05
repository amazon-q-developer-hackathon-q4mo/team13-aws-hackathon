# LiveInsight 개발 가이드라인

## 프로젝트 개요
- **서비스명**: LiveInsight (실시간 웹 분석 서비스)
- **해커톤 기간**: 24시간
- **팀 구성**: 백엔드 개발자 2명 (담당자 A: 인프라, 담당자 B: 비즈니스 로직)
- **목표**: 동작하는 MVP 완성

## 기술스택
- **백엔드**: Python 3.11 + FastAPI + Mangum (Lambda)
- **인프라**: Terraform + AWS (Lambda, DynamoDB, API Gateway)
- **프론트엔드**: HTMX + Tailwind CSS + Chart.js (CDN)
- **데이터베이스**: DynamoDB (On-Demand)

## 프로젝트 구조
```
liveinsight/
├── src/                      # Python 소스코드
│   ├── handlers/             # Lambda 핸들러
│   ├── models/               # 데이터 모델
│   ├── services/             # 비즈니스 로직
│   └── utils/                # 유틸리티
├── terraform/                # 인프라 코드
├── static/                   # 정적 파일 (대시보드)
└── scripts/                  # 빌드/배포 스크립트
```

## API 엔드포인트 규칙
- **이벤트 수집**: `POST /api/events`
- **실시간 데이터**: `GET /api/realtime`
- **통계 데이터**: `GET /api/stats`
- **대시보드**: `GET /dashboard` (정적 파일)

## DynamoDB 스키마 (MVP)
### Events 테이블
- PK: `session_id` (String)
- SK: `timestamp` (Number)
- TTL: 24시간 자동 삭제

### Sessions 테이블
- PK: `session_id` (String)
- GSI: `is_active` + `last_activity`

## 코딩 규칙
1. **Python**: PEP 8 준수, Type Hints 필수
2. **함수명**: snake_case 사용
3. **상수**: UPPER_CASE 사용
4. **에러 처리**: try-except 블록 필수
5. **로깅**: 모든 Lambda 함수에 logging 추가

## 환경변수 규칙
- `EVENTS_TABLE`: Events 테이블 이름
- `SESSIONS_TABLE`: Sessions 테이블 이름
- `AWS_REGION`: ap-northeast-2 (서울)

## 개발 우선순위
### Phase 1 (해커톤 24시간)
1. 이벤트 수집 API
2. 실시간 접속자 수 조회
3. 기본 대시보드 (HTMX)
4. 추적 스크립트 (liveinsight.js)

### 제외 기능
- 사용자 인증
- 멀티사이트 지원 (Phase 2)
- WebSocket (폴링 방식 사용)
- 복잡한 분석 기능

## 성능 목표
- API 응답시간: <100ms
- 동시 처리: 1000 req/min
- 데이터 보존: 24시간 (TTL)

## 보안 규칙
- HTTPS 필수
- API Key 기반 인증
- CORS 설정 필수
- IP 마스킹 (개인정보 보호)

## 배포 규칙
- Terraform으로 인프라 관리
- 환경: dev (개발), prod (운영)
- 리전: ap-northeast-2 (서울)
- 네이밍: `liveinsight-{resource}-{environment}`

## 테스트 규칙
- 단위 테스트: pytest 사용
- API 테스트: curl 또는 Postman
- 로컬 개발: DynamoDB Local 사용

## 문서화 규칙
- 모든 함수에 docstring 추가
- README.md 업데이트 필수
- API 문서는 FastAPI 자동 생성 활용

## 협업 규칙
- 담당자 A: terraform/ 디렉토리 담당
- 담당자 B: src/ 디렉토리 담당
- 공통: static/, scripts/ 디렉토리
- 충돌 방지: 각자 담당 영역 준수

## 응급 상황 대응
- 빌드 실패: scripts/build.sh 확인
- 배포 실패: terraform plan 먼저 실행
- API 오류: CloudWatch 로그 확인
- DynamoDB 오류: 테이블 존재 여부 확인