# Phase 1: 초기 설정 (1시간) - 개발자 A

## 목표
AWS 환경 설정 및 DynamoDB 테이블 스키마 설계

## 작업 내용

### 1. AWS 계정 설정 및 권한 구성 (30분)
**AWS CLI 설정**
```bash
aws configure
# Access Key ID: [YOUR_ACCESS_KEY]
# Secret Access Key: [YOUR_SECRET_KEY]
# Default region: us-east-1
# Default output format: json
```

**IAM 사용자 생성**
- 사용자명: liveinsight-dev
- 필요 권한:
  - DynamoDBFullAccess
  - AWSLambdaFullAccess
  - AmazonAPIGatewayAdministrator
  - CloudWatchFullAccess

### 2. DynamoDB 테이블 스키마 설계 (30분)

**Events 테이블**
```json
{
  "TableName": "LiveInsight-Events",
  "KeySchema": [
    {"AttributeName": "event_id", "KeyType": "HASH"},
    {"AttributeName": "timestamp", "KeyType": "RANGE"}
  ],
  "AttributeDefinitions": [
    {"AttributeName": "event_id", "AttributeType": "S"},
    {"AttributeName": "timestamp", "AttributeType": "N"},
    {"AttributeName": "user_id", "AttributeType": "S"},
    {"AttributeName": "session_id", "AttributeType": "S"}
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "UserIndex",
      "KeySchema": [
        {"AttributeName": "user_id", "KeyType": "HASH"},
        {"AttributeName": "timestamp", "KeyType": "RANGE"}
      ]
    },
    {
      "IndexName": "SessionIndex",
      "KeySchema": [
        {"AttributeName": "session_id", "KeyType": "HASH"},
        {"AttributeName": "timestamp", "KeyType": "RANGE"}
      ]
    }
  ]
}
```

**Sessions 테이블**
```json
{
  "TableName": "LiveInsight-Sessions",
  "KeySchema": [
    {"AttributeName": "session_id", "KeyType": "HASH"}
  ],
  "AttributeDefinitions": [
    {"AttributeName": "session_id", "AttributeType": "S"},
    {"AttributeName": "user_id", "AttributeType": "S"},
    {"AttributeName": "start_time", "AttributeType": "N"}
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "UserIndex",
      "KeySchema": [
        {"AttributeName": "user_id", "KeyType": "HASH"},
        {"AttributeName": "start_time", "KeyType": "RANGE"}
      ]
    }
  ]
}
```

**ActiveSessions 테이블**
```json
{
  "TableName": "LiveInsight-ActiveSessions",
  "KeySchema": [
    {"AttributeName": "session_id", "KeyType": "HASH"}
  ],
  "AttributeDefinitions": [
    {"AttributeName": "session_id", "AttributeType": "S"}
  ],
  "TimeToLiveSpecification": {
    "AttributeName": "expires_at",
    "Enabled": true
  }
}
```

## ✅ 완료 기준
- [x] AWS CLI 설정 완료 (us-east-1)
- [x] IAM 사용자 및 권한 설정 완료 (Hackathon 사용자)
- [x] 3개 테이블 스키마 설계 문서 완성
- [x] GSI 설계 완료
- [x] 테라폼 코드 작성 완료

## 📋 Phase 1 작업 결과

### 완료된 작업
1. **AWS 환경 설정**
   - AWS CLI 설정 확인: us-east-1 리전
   - IAM 사용자: Hackathon (권한 확인 완료)

2. **DynamoDB 테이블 스키마 설계**
   - Events 테이블: event_id(HASH) + timestamp(RANGE)
   - Sessions 테이블: session_id(HASH)
   - ActiveSessions 테이블: session_id(HASH) + TTL
   - GSI 설계: UserIndex, SessionIndex

3. **테라폼 인프라 코드**
   - main.tf: 테이블 정의 완료
   - variables.tf: 환경 변수 설정
   - outputs.tf: 출력값 정의
   - terraform.tfvars: 변수값 설정

### 생성된 파일
- `/infrastructure/main.tf`
- `/infrastructure/variables.tf`
- `/infrastructure/outputs.tf`
- `/infrastructure/terraform.tfvars`

### 다음 단계 준비
- 테라폼 초기화 완료 (`terraform init`)
- 테라폼 플랜 검증 완료 (`terraform plan`)
- Phase 2 배포 준비 완료