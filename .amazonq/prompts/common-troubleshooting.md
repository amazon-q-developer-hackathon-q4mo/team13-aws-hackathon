# 공통 문제 해결 가이드

## 자주 발생하는 문제들

### 1. Terraform 배포 실패
```bash
# 문제: 리소스 충돌
# 해결: 상태 파일 확인
terraform state list
terraform state show aws_lambda_function.event_collector

# 문제: 권한 부족
# 해결: AWS 자격증명 확인
aws sts get-caller-identity
```

### 2. Lambda 함수 오류
```bash
# 로그 확인
aws logs tail /aws/lambda/liveinsight-event-collector-dev --follow

# 일반적인 오류들:
# - 환경변수 누락: EVENTS_TABLE, SESSIONS_TABLE 확인
# - 패키지 누락: requirements.txt 확인
# - 권한 부족: IAM 역할 확인
```

### 3. DynamoDB 연결 오류
```python
# 테이블 존재 확인
import boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('liveinsight-events-dev')
print(table.table_status)

# 일반적인 오류들:
# - 테이블 없음: Terraform 배포 확인
# - 권한 부족: IAM 정책 확인
# - 리전 불일치: AWS_REGION 환경변수 확인
```

### 4. API Gateway CORS 오류
```javascript
// 브라우저 콘솔 오류 시
// 1. API Gateway CORS 설정 확인
// 2. OPTIONS 메서드 추가 확인
// 3. 헤더 허용 목록 확인

// 테스트 방법
curl -X OPTIONS https://api-url/api/events \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST"
```

### 5. 로컬 개발 환경 문제
```bash
# DynamoDB Local 실행
docker run -p 8000:8000 amazon/dynamodb-local

# 환경변수 설정
export EVENTS_TABLE=liveinsight-events-dev
export SESSIONS_TABLE=liveinsight-sessions-dev
export AWS_REGION=ap-northeast-2

# FastAPI 로컬 실행
cd src && uvicorn handlers.event_collector:app --reload
```

## 디버깅 체크리스트

### 배포 전 확인사항
- [ ] Terraform plan 실행 성공
- [ ] AWS 자격증명 설정 확인
- [ ] 환경변수 설정 확인
- [ ] Python 의존성 설치 확인

### API 테스트 체크리스트
- [ ] 엔드포인트 URL 확인
- [ ] HTTP 메서드 확인 (POST/GET)
- [ ] 헤더 설정 확인 (Content-Type, CORS)
- [ ] 요청 바디 형식 확인 (JSON)

### 성능 문제 해결
- [ ] CloudWatch 메트릭 확인
- [ ] Lambda 메모리 사용량 확인
- [ ] DynamoDB 읽기/쓰기 용량 확인
- [ ] API Gateway 응답 시간 확인

## 응급 상황 대응

### 서비스 다운 시
1. CloudWatch 알람 확인
2. Lambda 함수 로그 확인
3. DynamoDB 상태 확인
4. API Gateway 상태 확인

### 데이터 손실 시
1. DynamoDB 백업 확인
2. CloudTrail 로그 확인
3. 최근 배포 이력 확인

### 보안 이슈 시
1. API Key 로테이션
2. IAM 권한 재검토
3. CloudTrail 감사 로그 확인

## 연락처 및 리소스
- AWS 콘솔: https://console.aws.amazon.com
- CloudWatch 로그: /aws/lambda/liveinsight-*
- Terraform 문서: https://registry.terraform.io/providers/hashicorp/aws
- FastAPI 문서: https://fastapi.tiangolo.com