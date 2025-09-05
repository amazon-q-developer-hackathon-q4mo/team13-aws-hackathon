# 개발자 A - 인프라/백엔드 세부 계획

## 담당 영역
- AWS 인프라 구축 및 관리
- Lambda 함수 개발
- DynamoDB 설계 및 구현
- API Gateway 설정

## Phase별 상세 작업

### Phase 1: 초기 설정 (1시간)
**AWS 계정 설정 및 권한 구성**
- IAM 사용자 생성 및 필요 권한 부여
- AWS CLI 설정
- 개발 환경 리전 설정 (ap-northeast-2)

**DynamoDB 테이블 스키마 설계**
- Events 테이블 구조 확정
- Sessions 테이블 구조 확정
- ActiveSessions 테이블 구조 확정
- GSI 설계 완료

### Phase 2: 인프라 구축 (2시간)
**DynamoDB 테이블 생성**
```
- Events: PK=event_id, SK=timestamp
- Sessions: PK=session_id
- ActiveSessions: PK=session_id, TTL=expires_at
```

**API Gateway 설정**
- REST API 생성
- /events POST 엔드포인트 생성
- CORS 설정 (모든 도메인 허용)
- 요청 검증 설정

**Lambda 함수 기본 구조**
- event-collector 함수 생성
- Python 3.9 런타임 설정
- DynamoDB 접근 권한 설정

**IAM 역할 및 정책**
- Lambda 실행 역할 생성
- DynamoDB 읽기/쓰기 권한 부여
- CloudWatch 로그 권한 설정

### Phase 3: 핵심 기능 개발 (4시간)
**이벤트 수집 Lambda 함수**
- 이벤트 데이터 파싱 및 검증
- 세션 ID 생성 로직
- Events 테이블 저장 로직

**세션 관리 로직**
- 새 세션 생성 처리
- 기존 세션 업데이트
- 세션 만료 처리 (30분 TTL)
- ActiveSessions 테이블 관리

**DynamoDB 데이터 저장**
- 배치 쓰기 최적화
- 에러 처리 및 재시도 로직
- 데이터 일관성 보장

**Lambda-API Gateway 연동**
- 응답 형식 표준화
- 에러 응답 처리
- 성능 테스트 및 최적화

### Phase 4: 최적화 및 모니터링 (3시간)
**Lambda 함수 최적화**
- 콜드 스타트 최소화
- 메모리 사용량 최적화
- 실행 시간 단축

**CloudWatch 로깅**
- 구조화된 로그 형식 설정
- 에러 로그 분류
- 성능 메트릭 수집

**API 성능 테스트**
- 부하 테스트 시나리오 작성
- 응답 시간 측정
- 처리량 한계 확인

### Phase 5: 최종 점검 (2시간)
**인프라 최종 점검**
- 모든 AWS 리소스 상태 확인
- 보안 설정 검토
- 비용 최적화 확인

**성능 모니터링 설정**
- CloudWatch 대시보드 구성
- 알람 설정 (에러율, 응답시간)
- X-Ray 트레이싱 활성화

**배포 스크립트**
- Infrastructure as Code 작성
- 자동 배포 스크립트 준비
- 롤백 계획 수립

## 주요 산출물
- DynamoDB 테이블 3개
- Lambda 함수 1개
- API Gateway REST API
- IAM 역할 및 정책
- CloudWatch 모니터링 설정