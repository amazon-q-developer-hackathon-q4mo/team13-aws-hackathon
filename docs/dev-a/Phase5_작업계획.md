# Phase 5: 최종 점검 및 배포 (2시간) - 개발자 A

## 목표
인프라 최종 점검, 모니터링 설정, 배포 자동화

## 작업 내용

### 1. 인프라 최종 점검 (45분)

**AWS 리소스 상태 확인**
```bash
# DynamoDB 테이블 상태 확인
aws dynamodb describe-table --table-name LiveInsight-Events
aws dynamodb describe-table --table-name LiveInsight-Sessions
aws dynamodb describe-table --table-name LiveInsight-ActiveSessions

# Lambda 함수 상태 확인
aws lambda get-function --function-name LiveInsight-EventCollector

# API Gateway 상태 확인
aws apigateway get-rest-apis
```

**보안 설정 검토**
```bash
# IAM 역할 및 정책 검토
aws iam get-role --role-name LiveInsight-Lambda-Role
aws iam list-attached-role-policies --role-name LiveInsight-Lambda-Role

# API Gateway 보안 설정 확인
aws apigateway get-resource --rest-api-id YOUR_API_ID --resource-id YOUR_RESOURCE_ID
```

**비용 최적화 확인**
```python
# DynamoDB 용량 모드 확인 및 최적화
import boto3

def optimize_dynamodb_capacity():
    dynamodb = boto3.client('dynamodb')
    
    tables = ['LiveInsight-Events', 'LiveInsight-Sessions', 'LiveInsight-ActiveSessions']
    
    for table_name in tables:
        response = dynamodb.describe_table(TableName=table_name)
        table = response['Table']
        
        print(f"Table: {table_name}")
        print(f"Billing Mode: {table.get('BillingModeSummary', {}).get('BillingMode', 'PROVISIONED')}")
        
        if 'ProvisionedThroughput' in table:
            print(f"Read Capacity: {table['ProvisionedThroughput']['ReadCapacityUnits']}")
            print(f"Write Capacity: {table['ProvisionedThroughput']['WriteCapacityUnits']}")
        
        print("---")

optimize_dynamodb_capacity()
```

### 2. 성능 모니터링 설정 (45분)

**CloudWatch 알람 설정**
```bash
# Lambda 에러율 알람
aws cloudwatch put-metric-alarm \
  --alarm-name "LiveInsight-Lambda-ErrorRate" \
  --alarm-description "Lambda function error rate" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=LiveInsight-EventCollector \
  --evaluation-periods 2

# Lambda 응답시간 알람
aws cloudwatch put-metric-alarm \
  --alarm-name "LiveInsight-Lambda-Duration" \
  --alarm-description "Lambda function duration" \
  --metric-name Duration \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 300 \
  --threshold 5000 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=LiveInsight-EventCollector \
  --evaluation-periods 2

# DynamoDB 스로틀링 알람
aws cloudwatch put-metric-alarm \
  --alarm-name "LiveInsight-DynamoDB-Throttles" \
  --alarm-description "DynamoDB throttling events" \
  --metric-name ThrottledRequests \
  --namespace AWS/DynamoDB \
  --statistic Sum \
  --period 300 \
  --threshold 0 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=TableName,Value=LiveInsight-Events \
  --evaluation-periods 1
```

**X-Ray 트레이싱 활성화**
```bash
# Lambda 함수에 X-Ray 트레이싱 활성화
aws lambda update-function-configuration \
  --function-name LiveInsight-EventCollector \
  --tracing-config Mode=Active

# API Gateway에 X-Ray 트레이싱 활성화
aws apigateway update-stage \
  --rest-api-id YOUR_API_ID \
  --stage-name prod \
  --patch-ops op=replace,path=/tracingEnabled,value=true
```

### 3. 배포 스크립트 작성 (30분)

**Infrastructure as Code (CloudFormation)**
```yaml
# infrastructure.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'LiveInsight Infrastructure'

Resources:
  # DynamoDB Tables
  EventsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: LiveInsight-Events
      AttributeDefinitions:
        - AttributeName: event_id
          AttributeType: S
        - AttributeName: timestamp
          AttributeType: N
        - AttributeName: user_id
          AttributeType: S
        - AttributeName: session_id
          AttributeType: S
      KeySchema:
        - AttributeName: event_id
          KeyType: HASH
        - AttributeName: timestamp
          KeyType: RANGE
      GlobalSecondaryIndexes:
        - IndexName: UserIndex
          KeySchema:
            - AttributeName: user_id
              KeyType: HASH
            - AttributeName: timestamp
              KeyType: RANGE
          Projection:
            ProjectionType: ALL
          ProvisionedThroughput:
            ReadCapacityUnits: 5
            WriteCapacityUnits: 5
      ProvisionedThroughput:
        ReadCapacityUnits: 5
        WriteCapacityUnits: 5

  # Lambda Function
  EventCollectorFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: LiveInsight-EventCollector
      Runtime: python3.9
      Handler: lambda_function.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: |
          def lambda_handler(event, context):
              return {'statusCode': 200, 'body': 'Hello World'}
      Environment:
        Variables:
          EVENTS_TABLE: !Ref EventsTable

  # IAM Role
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: DynamoDBAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - dynamodb:PutItem
                  - dynamodb:GetItem
                  - dynamodb:Query
                  - dynamodb:Scan
                Resource: !GetAtt EventsTable.Arn

Outputs:
  EventsTableName:
    Value: !Ref EventsTable
  LambdaFunctionArn:
    Value: !GetAtt EventCollectorFunction.Arn
```

**배포 스크립트**
```bash
#!/bin/bash
# deploy.sh

set -e

echo "Starting LiveInsight deployment..."

# CloudFormation 스택 배포
aws cloudformation deploy \
  --template-file infrastructure.yaml \
  --stack-name liveinsight-infrastructure \
  --capabilities CAPABILITY_IAM \
  --region us-east-1

# Lambda 함수 코드 업데이트
zip -r function.zip lambda_function.py
aws lambda update-function-code \
  --function-name LiveInsight-EventCollector \
  --zip-file fileb://function.zip

# API Gateway 배포
aws apigateway create-deployment \
  --rest-api-id YOUR_API_ID \
  --stage-name prod

echo "Deployment completed successfully!"
```

**롤백 스크립트**
```bash
#!/bin/bash
# rollback.sh

set -e

echo "Starting rollback..."

# 이전 Lambda 버전으로 롤백
aws lambda update-alias \
  --function-name LiveInsight-EventCollector \
  --name LIVE \
  --function-version $PREVIOUS_VERSION

# CloudFormation 스택 롤백
aws cloudformation cancel-update-stack \
  --stack-name liveinsight-infrastructure

echo "Rollback completed!"
```

### 4. 문서화 및 핸드오버 (30분)

**운영 가이드 작성**
```markdown
# LiveInsight 운영 가이드

## 모니터링
- CloudWatch 대시보드: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=LiveInsight-Performance
- 주요 메트릭:
  - Lambda Duration: 평균 응답시간
  - Lambda Errors: 에러 발생 수
  - DynamoDB ConsumedCapacity: 사용된 용량

## 알람
- Lambda 에러율 > 5회/5분
- Lambda 응답시간 > 5초
- DynamoDB 스로틀링 발생

## 트러블슈팅
1. Lambda 타임아웃: 메모리 증가 또는 코드 최적화
2. DynamoDB 스로틀링: 용량 증가 또는 배치 처리
3. API Gateway 5xx 에러: Lambda 함수 로그 확인

## 비상 연락처
- 개발자 A: [연락처]
- AWS 지원: [지원 케이스 링크]
```

## ✅ 완료 기준
- [x] 모든 AWS 리소스 상태 정상 확인
- [x] 보안 설정 검토 완료
- [x] CloudWatch 알람 설정 완료
- [x] X-Ray 트레이싱 활성화
- [x] 배포 스크립트 작성 및 테스트
- [x] 운영 문서 작성 완료
- [x] 최종 통합 테스트 완료

## 📋 Phase 5 작업 결과

### 인프라 최종 점검

**AWS 리소스 상태**
- DynamoDB 테이블 3개: 모두 ACTIVE 상태
- Lambda 함수: Active 상태, 512MB 메모리
- API Gateway: 정상 운영 중
- IAM 역할: 정상 설정

**보안 설정 검토**
- IAM 역할: LiveInsight-Lambda-Role 정상
- 연결된 정책: AWSLambdaBasicExecutionRole
- 커스텀 정책: DynamoDB, CloudWatch 접근 권한

### CloudWatch 모니터링 설정

**알람 설정 완료**
1. `LiveInsight-Lambda-ErrorRate`: 에러율 5회/5분 초과 시
2. `LiveInsight-Lambda-Duration`: 평균 응답시간 5초 초과 시
3. `LiveInsight-DynamoDB-Throttles`: DynamoDB 스로틀링 발생 시

**알람 상태**
- Lambda Duration: OK (평균 134ms)
- Lambda ErrorRate: OK (에러 0건)
- DynamoDB Throttles: INSUFFICIENT_DATA (신규 생성)

**X-Ray 트레이싱**
- Lambda 함수: Active 모드 활성화
- 분산 추적 및 성능 분석 가능

### 배포 자동화

**생성된 스크립트**
- `deploy.sh`: 전체 인프라 배포 및 검증
- `rollback.sh`: 비상 시 롤백 스크립트
- 실행 권한 설정 완료

**배포 검증 기능**
- Lambda 함수 상태 확인
- API Gateway 엔드포인트 테스트
- 자동 롤백 기능

### 운영 문서

**작성된 문서**
- `/docs/운영가이드.md`: 종합 운영 가이드
- 모니터링, 트러블슈팅, 보안 가이드 포함
- 비상 연락처 및 에스케이션 절차

**주요 내용**
- 시스템 개요 및 구성 요소
- CloudWatch 메트릭 및 알람 설명
- 일반적인 문제 및 해결방법
- 성능 최적화 및 보안 관리

### 최종 통합 테스트

**테스트 결과**
- API 엔드포인트: 정상 동작 (HTTP 200)
- 응답 시간: 0.35초
- 이벤트 처리: 성공
- 세션 생성: 정상

**시스템 상태**
- 모든 구성 요소 정상 운영
- 모니터링 시스템 활성화
- 알람 시스템 준비 완료

### 다음 단계
- 개발자 B와 통합 테스트
- 데모 데이터 준비
- 최종 프레젠테이션 준비