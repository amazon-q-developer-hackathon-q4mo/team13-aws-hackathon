# Phase 2: 인프라 구축 (2시간) - 개발자 A

## 목표
DynamoDB 테이블 생성, API Gateway 설정, Lambda 함수 기본 구조 생성

## 작업 내용

### 1. DynamoDB 테이블 생성 (45분)

**Events 테이블 생성**
```bash
aws dynamodb create-table \
  --table-name LiveInsight-Events \
  --attribute-definitions \
    AttributeName=event_id,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
    AttributeName=user_id,AttributeType=S \
    AttributeName=session_id,AttributeType=S \
  --key-schema \
    AttributeName=event_id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --global-secondary-indexes \
    IndexName=UserIndex,KeySchema=[{AttributeName=user_id,KeyType=HASH},{AttributeName=timestamp,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
    IndexName=SessionIndex,KeySchema=[{AttributeName=session_id,KeyType=HASH},{AttributeName=timestamp,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

**Sessions 테이블 생성**
```bash
aws dynamodb create-table \
  --table-name LiveInsight-Sessions \
  --attribute-definitions \
    AttributeName=session_id,AttributeType=S \
    AttributeName=user_id,AttributeType=S \
    AttributeName=start_time,AttributeType=N \
  --key-schema AttributeName=session_id,KeyType=HASH \
  --global-secondary-indexes \
    IndexName=UserIndex,KeySchema=[{AttributeName=user_id,KeyType=HASH},{AttributeName=start_time,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

**ActiveSessions 테이블 생성**
```bash
aws dynamodb create-table \
  --table-name LiveInsight-ActiveSessions \
  --attribute-definitions AttributeName=session_id,AttributeType=S \
  --key-schema AttributeName=session_id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

aws dynamodb update-time-to-live \
  --table-name LiveInsight-ActiveSessions \
  --time-to-live-specification Enabled=true,AttributeName=expires_at
```

### 2. IAM 역할 및 정책 설정 (30분)

**Lambda 실행 역할 생성**
```bash
# 신뢰 정책 파일 생성
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# IAM 역할 생성
aws iam create-role \
  --role-name LiveInsight-Lambda-Role \
  --assume-role-policy-document file://trust-policy.json

# 기본 실행 정책 연결
aws iam attach-role-policy \
  --role-name LiveInsight-Lambda-Role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# DynamoDB 접근 정책 생성 및 연결
cat > dynamodb-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:ap-northeast-2:*:table/LiveInsight-Events",
        "arn:aws:dynamodb:ap-northeast-2:*:table/LiveInsight-Sessions",
        "arn:aws:dynamodb:ap-northeast-2:*:table/LiveInsight-ActiveSessions",
        "arn:aws:dynamodb:ap-northeast-2:*:table/LiveInsight-Events/index/*",
        "arn:aws:dynamodb:ap-northeast-2:*:table/LiveInsight-Sessions/index/*"
      ]
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name LiveInsight-DynamoDB-Policy \
  --policy-document file://dynamodb-policy.json

aws iam attach-role-policy \
  --role-name LiveInsight-Lambda-Role \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/LiveInsight-DynamoDB-Policy
```

### 3. API Gateway 설정 (45분)

**REST API 생성**
```bash
aws apigateway create-rest-api --name LiveInsight-API
```

**리소스 및 메서드 생성**
- /events 리소스 생성
- POST 메서드 추가
- CORS 설정

**CORS 설정**
```json
{
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
  "Access-Control-Allow-Methods": "POST,OPTIONS"
}
```

### 4. Lambda 함수 기본 구조 (30분)

**함수 생성**
```bash
# 기본 함수 코드 작성
cat > lambda_function.py << EOF
import json
import os

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'message': 'Event received'})
    }
EOF

# 배포 패키지 생성
zip function.zip lambda_function.py

# Lambda 함수 생성
aws lambda create-function \
  --function-name LiveInsight-EventCollector \
  --runtime python3.9 \
  --role arn:aws:iam::ACCOUNT_ID:role/LiveInsight-Lambda-Role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip \
  --environment Variables='{"EVENTS_TABLE":"LiveInsight-Events","SESSIONS_TABLE":"LiveInsight-Sessions","ACTIVE_SESSIONS_TABLE":"LiveInsight-ActiveSessions"}'
```

**기본 코드 구조**
```python
import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    # TODO: 이벤트 처리 로직 구현
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'message': 'Event received'})
    }
```

## 완료 기준
- [ ] 3개 DynamoDB 테이블 생성 완료
- [ ] IAM 역할 및 정책 설정 완료
- [ ] API Gateway REST API 생성
- [ ] /events POST 엔드포인트 설정
- [ ] Lambda 함수 생성 및 기본 구조 완성
- [ ] 환경 변수 설정 완료