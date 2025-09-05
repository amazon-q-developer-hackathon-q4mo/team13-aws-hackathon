# 담당자 A - 인프라 개발 가이드

## 담당 영역
- Terraform 인프라 코드 작성
- AWS 리소스 배포 및 관리
- CI/CD 파이프라인 구축
- 모니터링 및 로깅 설정

## 작업 디렉토리
- `terraform/` - 모든 인프라 코드
- `scripts/` - 빌드/배포 스크립트 (공통)

## Terraform 구조
```
terraform/
├── main.tf          # Provider 설정
├── variables.tf     # 변수 정의
├── outputs.tf       # 출력값
├── lambda.tf        # Lambda 함수
├── dynamodb.tf      # DynamoDB 테이블
├── api_gateway.tf   # API Gateway
├── s3.tf           # S3 + CloudFront
└── monitoring.tf    # CloudWatch 알람
```

## 필수 리소스
### Lambda 함수 (3개)
- `liveinsight-event-collector-dev`
- `liveinsight-realtime-api-dev`
- `liveinsight-stats-api-dev`

### DynamoDB 테이블 (2개)
- `liveinsight-events-dev` (TTL 설정)
- `liveinsight-sessions-dev` (GSI 설정)

### API Gateway
- REST API 타입
- CORS 활성화
- Rate Limiting: 1000 req/min

## 환경변수 설정
```hcl
environment {
  variables = {
    EVENTS_TABLE   = aws_dynamodb_table.events.name
    SESSIONS_TABLE = aws_dynamodb_table.sessions.name
    AWS_REGION     = var.aws_region
  }
}
```

## 네이밍 규칙
- 리소스명: `${var.project_name}-${resource}-${var.environment}`
- 태그: Name, Environment, Project 필수

## 보안 설정
- IAM 최소 권한 원칙
- DynamoDB 암호화 활성화
- API Gateway CORS 설정
- CloudTrail 로깅 활성화

## 모니터링 설정
- Lambda 에러 알람
- DynamoDB 스로틀링 알람
- API Gateway 4xx/5xx 알람
- 비용 알람 설정

## 배포 스크립트
```bash
# scripts/deploy.sh
terraform init
terraform plan
terraform apply -auto-approve
```

## 로컬 테스트
- DynamoDB Local 사용
- LocalStack 활용 (선택사항)

## 주의사항
- 담당자 B의 src/ 코드 변경 시 Lambda 재배포 필요
- DynamoDB 스키마 변경 시 사전 협의
- API Gateway 엔드포인트 변경 시 문서 업데이트