# LiveInsight Infrastructure

## Phase 1 완료 상태

### ✅ AWS 계정 설정 및 권한 구성
- AWS CLI 설정 완료 (us-east-1)
- IAM 사용자 확인 완료 (Hackathon)
- 필요 권한 확인 완료

### ✅ DynamoDB 테이블 스키마 설계
- Events 테이블 스키마 완료
- Sessions 테이블 스키마 완료
- ActiveSessions 테이블 스키마 완료 (TTL 포함)

## 테라폼 배포 명령어

### 초기화 (완료)
```bash
terraform init
```

### 계획 확인 (완료)
```bash
terraform plan
```

### 배포 실행
```bash
terraform apply
```

### 리소스 삭제
```bash
terraform destroy
```

## ✅ Phase 2 완료 상태

### 배포된 리소스 (17개)
- **DynamoDB 테이블**: 3개 (Events, Sessions, ActiveSessions)
- **IAM 역할**: LiveInsight-Lambda-Role
- **Lambda 함수**: LiveInsight-EventCollector (512MB, 30초)
- **API Gateway**: LiveInsight-API with /events endpoint
- **CORS 설정**: 완료

### 🚀 API Gateway URL (개발자 B 전달용)
```
https://qnwoi1ardd.execute-api.us-east-1.amazonaws.com/prod
```

### API 테스트 결과
```json
{
  "message": "Event processed successfully",
  "event_id": "evt_20250905_153409_3a7c66d5",
  "session_id": "sess_20250905_3ef5a49f"
}
```

## 다음 단계 (Phase 3)
- 세션 관리 로직 고도화
- 에러 처리 강화
- 성능 최적화

## 환경 변수 설정
```env
EVENTS_TABLE=LiveInsight-Events
SESSIONS_TABLE=LiveInsight-Sessions
ACTIVE_SESSIONS_TABLE=LiveInsight-ActiveSessions
```