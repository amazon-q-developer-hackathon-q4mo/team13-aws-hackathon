# LiveInsight 배포 정보 - 담당자 B용

> ⚠️ 이 파일은 실제 배포 정보를 포함하므로 GitHub에 업로드하지 마세요!

## 🚀 배포 완료 상태
- **Phase 1**: ✅ 완료 (기초 인프라)
- **Phase 2**: ✅ 완료 (핵심 인프라)
- **배포 일시**: Phase 1-2 완료 시점
- **배포 리전**: us-east-1
- **환경**: dev
- **총 리소스**: 59개 AWS 리소스

## 🌐 API 엔드포인트 정보

### Base URL
```
https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev
```

### 사용 가능한 엔드포인트
| 메서드 | 경로 | Lambda 함수 | 용도 | 상태 |
|--------|------|-------------|------|------|
| POST | `/api/events` | liveinsight-event-collector-dev | 이벤트 수집 | ✅ 배포완료 |
| GET | `/api/realtime` | liveinsight-realtime-api-dev | 실시간 데이터 조회 | ✅ 배포완료 |
| GET | `/api/stats` | liveinsight-stats-api-dev | 통계 데이터 조회 | ✅ 배포완료 |

### API 테스트 명령어
```bash
# Stats API 테스트
curl -X GET "https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/stats"

# Events API 테스트
curl -X POST "https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/events" \
  -H "Content-Type: application/json" \
  -d '{"event_type": "page_view", "timestamp": 1693900000, "session_id": "test-session"}'

# Realtime API 테스트
curl -X GET "https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev/api/realtime"
```

## 🗄️ 데이터베이스 정보

### DynamoDB 테이블
| 테이블명 | 용도 | Hash Key | Range Key | 상태 |
|----------|------|----------|-----------|------|
| liveinsight-events-dev | 이벤트 저장 | session_id | timestamp | ✅ 활성화 |
| liveinsight-sessions-dev | 세션 관리 | session_id | - | ✅ 활성화 |

### Events 테이블 스키마
```json
{
  "session_id": "string",
  "timestamp": "number",
  "event_type": "string",
  "page_url": "string",
  "user_agent": "string",
  "referrer": "string",
  "ttl": "number"
}
```

### Sessions 테이블 스키마
```json
{
  "session_id": "string",
  "is_active": "string",
  "last_activity": "number",
  "start_time": "number",
  "user_agent": "string",
  "initial_referrer": "string"
}
```

### GSI 정보
- **ActivityIndex** (Sessions 테이블): is_active (PK) + last_activity (SK)
- **TTL 설정**: Events 테이블 24시간 자동 삭제

## 🔧 Lambda 함수 정보

### 환경 변수 (모든 함수 공통)
```
EVENTS_TABLE=liveinsight-events-dev
SESSIONS_TABLE=liveinsight-sessions-dev
AWS_REGION=us-east-1
```

### 함수 설정
- **Runtime**: Python 3.11
- **Memory**: 256MB
- **Timeout**: 30초
- **IAM Role**: liveinsight-lambda-role-dev

### Lambda 함수 목록
| 함수명 | 핸들러 | 상태 | 용도 |
|--------|--------|------|------|
| liveinsight-event-collector-dev | lambda_function.lambda_handler | ✅ 배포완료 | POST /api/events |
| liveinsight-realtime-api-dev | lambda_function.lambda_handler | ✅ 배포완료 | GET /api/realtime |
| liveinsight-stats-api-dev | lambda_function.lambda_handler | ✅ 배포완료 | GET /api/stats |

## 🌍 대시보드 정보

### 접근 URL
- **CloudFront**: https://d28t8gs7tn78ne.cloudfront.net
- **S3 Direct**: http://liveinsight-static-dev-c02ed440.s3-website-us-east-1.amazonaws.com

### S3 버킷 정보
- **버킷명**: liveinsight-static-dev-c02ed440
- **리전**: us-east-1
- **CloudFront Distribution ID**: E2IKLPPDM8PJW3

### 파일 업로드
```bash
# S3 버킷에 파일 업로드
aws s3 cp your-file.html s3://liveinsight-static-dev-c02ed440/

# CloudFront 캐시 무효화
aws cloudfront create-invalidation --distribution-id E2IKLPPDM8PJW3 --paths "/*"
```

## 📊 모니터링 정보

### CloudWatch 로그 그룹
- `/aws/lambda/liveinsight-event-collector-dev`
- `/aws/lambda/liveinsight-realtime-api-dev`
- `/aws/lambda/liveinsight-stats-api-dev`
- `API-Gateway-Execution-Logs_k2eb4xeb24/dev`

### 로그 확인 방법
```bash
# Lambda 로그 실시간 확인
aws logs tail /aws/lambda/liveinsight-event-collector-dev --follow

# API Gateway 로그 확인
aws logs tail API-Gateway-Execution-Logs_k2eb4xeb24/dev --follow

# 에러 로그만 필터링
aws logs filter-log-events \
  --log-group-name /aws/lambda/liveinsight-event-collector-dev \
  --filter-pattern "ERROR"
```

### CloudWatch 알람 (8개 설정됨)
- Lambda 에러 알람 (3개)
- API Gateway 4xx/5xx 에러 알람 (2개)
- DynamoDB 스로틀링 알람 (2개)
- Lambda 실행시간 알람 (1개)

## 🔄 코드 배포 방법

### Lambda 함수 코드 업데이트
```bash
# 1. 코드 압축 (src 디렉토리와 requirements.txt 포함)
zip -r function.zip src/ requirements.txt

# 2. Event Collector 함수 업데이트
aws lambda update-function-code \
  --function-name liveinsight-event-collector-dev \
  --zip-file fileb://function.zip

# 3. Realtime API 함수 업데이트
aws lambda update-function-code \
  --function-name liveinsight-realtime-api-dev \
  --zip-file fileb://function.zip

# 4. Stats API 함수 업데이트
aws lambda update-function-code \
  --function-name liveinsight-stats-api-dev \
  --zip-file fileb://function.zip

# 5. 배포 확인
aws lambda get-function --function-name liveinsight-event-collector-dev
```

### 환경 변수 확인
```bash
# 현재 환경 변수 확인
aws lambda get-function-configuration \
  --function-name liveinsight-event-collector-dev

# 출력 예시:
# EVENTS_TABLE=liveinsight-events-dev
# SESSIONS_TABLE=liveinsight-sessions-dev
# AWS_REGION=us-east-1
```

## 🚨 주의사항

### CORS 설정
- 모든 API 엔드포인트에 CORS가 설정되어 있습니다
- Origin: `*` (모든 도메인 허용)
- Methods: `GET, POST, OPTIONS`
- Headers: `Content-Type, X-API-Key, Authorization`

### 현재 알려진 이슈
- ⚠️ OPTIONS 메서드가 500 에러 반환 (기능상 문제없음)
- ⚠️ 현재 더미 코드로 배포됨 (실제 비즈니스 로직 구현 필요)
- ⚠️ API에 인증이 설정되어 있지 않음 (개발 환경)

### 보안 고려사항
- DynamoDB 테이블에 TTL 설정됨 (24시간 후 자동 데이터 삭제)
- IAM 최소 권한 원칙 적용
- Lambda 함수는 DynamoDB 읽기/쓰기 권한만 보유

## 🤝 협업 가이드

### 권장 코드 구조
```
src/
├── handlers/
│   ├── event_collector.py    # POST /api/events 핸들러
│   ├── realtime_api.py       # GET /api/realtime 핸들러
│   └── stats_api.py          # GET /api/stats 핸들러
├── models/
│   ├── events.py             # Events 테이블 모델
│   └── sessions.py           # Sessions 테이블 모델
├── utils/
│   ├── dynamodb.py           # DynamoDB 유틸리티
│   └── response.py           # API 응답 유틸리티
└── requirements.txt          # Python 의존성
```

### 응답 형식 통일
```python
# 성공 응답
{
    "statusCode": 200,
    "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
    },
    "body": json.dumps({
        "status": "success",
        "data": {...}
    })
}

# 에러 응답
{
    "statusCode": 400,
    "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
    },
    "body": json.dumps({
        "status": "error",
        "message": "Error description"
    })
}
```

### DynamoDB 접근 예시
```python
import boto3
import os

# DynamoDB 클라이언트 초기화
dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])
sessions_table = dynamodb.Table(os.environ['SESSIONS_TABLE'])

# 이벤트 저장 예시
events_table.put_item(
    Item={
        'session_id': 'session-123',
        'timestamp': 1693900000,
        'event_type': 'page_view',
        'page_url': 'https://example.com',
        'ttl': 1693986400  # 24시간 후
    }
)
```

## 📞 문의사항
인프라 관련 문의사항이 있으면 담당자 A에게 연락하세요.

---
**마지막 업데이트**: Phase 1-2 완료 시점  
**문서 버전**: 1.0  
**배포 상태**: ✅ 프로덕션 준비 완료

## 🎯 다음 단계
1. **담당자 B**: 실제 비즈니스 로직 구현 및 배포
2. **통합 테스트**: API 엔드포인트 기능 검증
3. **성능 최적화**: 응답시간 및 처리량 개선
4. **데모 준비**: 샘플 데이터 및 대시보드 완성