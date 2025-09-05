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
# Default region: ap-northeast-2
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

## 완료 기준
- [ ] AWS CLI 설정 완료
- [ ] IAM 사용자 및 권한 설정 완료
- [ ] 3개 테이블 스키마 설계 문서 완성
- [ ] GSI 설계 완료