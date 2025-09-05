# Phase 2: 핵심 인프라 구현 (4-12시간)

## 🎯 Phase 목표
- API Gateway 완전 구현
- S3 + CloudFront 정적 호스팅
- CORS 설정 및 API 연결
- 담당자 B 코드 배포 환경 완성

## ⏰ 세부 작업 일정

### 1단계: API Gateway 구현 (90분)
#### 작업 내용
- [ ] `terraform/api_gateway.tf` 생성
- [ ] REST API 생성
- [ ] 리소스 및 메서드 정의
- [ ] Lambda 통합 설정
- [ ] CORS 설정

#### API 구조
```
/api
├── /events (POST) → event-collector Lambda
├── /realtime (GET) → realtime-api Lambda
└── /stats (GET) → stats-api Lambda
```

#### CORS 설정 스펙
```hcl
# 모든 엔드포인트에 CORS 적용
cors {
  allow_credentials = false
  allow_headers     = ["Content-Type", "X-API-Key", "Authorization"]
  allow_methods     = ["GET", "POST", "OPTIONS"]
  allow_origins     = ["*"]  # 개발 단계에서는 와일드카드
  max_age          = 86400
}
```

#### 체크리스트
- [ ] REST API 생성 완료
- [ ] 3개 엔드포인트 정의 완료
- [ ] Lambda 통합 설정 완료
- [ ] CORS 설정 완료
- [ ] API 배포 스테이지 생성

### 2단계: S3 + CloudFront 설정 (60분)
#### 작업 내용
- [ ] `terraform/s3.tf` 생성
- [ ] S3 버킷 생성 (정적 웹사이트 호스팅)
- [ ] CloudFront 배포 설정
- [ ] 버킷 정책 설정

#### S3 버킷 스펙
```hcl
resource "aws_s3_bucket" "static_files" {
  bucket = "liveinsight-static-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_website_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id
  
  index_document {
    suffix = "dashboard.html"
  }
}
```

#### CloudFront 스펙
```hcl
resource "aws_cloudfront_distribution" "static_files" {
  origin {
    domain_name = aws_s3_bucket.static_files.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_files.id}"
  }
  
  default_cache_behavior {
    target_origin_id = "S3-${aws_s3_bucket.static_files.id}"
    compress         = true
    
    # 캐시 정책
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"  # CachingOptimized
  }
}
```

#### 체크리스트
- [ ] S3 버킷 생성 및 웹사이트 호스팅 설정
- [ ] CloudFront 배포 생성
- [ ] 버킷 정책 설정 (퍼블릭 읽기)
- [ ] 도메인 확인 및 테스트

### 3단계: 기본 모니터링 설정 (45분)
#### 작업 내용
- [ ] `terraform/monitoring.tf` 생성
- [ ] CloudWatch 로그 그룹 생성
- [ ] 기본 메트릭 알람 설정
- [ ] 로그 보존 기간 설정 (Phase 3에서 고도화)

#### 알람 설정
```hcl
# Lambda 에러 알람
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "liveinsight-lambda-errors-dev"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Lambda function errors"
}
```

#### 체크리스트
- [ ] Lambda 함수별 로그 그룹 생성
- [ ] 에러 알람 설정
- [ ] API Gateway 알람 설정
- [ ] 로그 보존 기간 설정 (7일)

### 4단계: 배포 스크립트 작성 (30분)
#### 작업 내용
- [ ] `scripts/deploy.sh` 생성
- [ ] `scripts/build.sh` 생성
- [ ] 환경별 배포 스크립트
- [ ] 헬스체크 스크립트

#### 배포 스크립트 스펙
```bash
#!/bin/bash
# scripts/deploy.sh
set -e

echo "🚀 LiveInsight Phase 2 배포 시작..."

cd terraform

# 초기화 및 계획
terraform init
terraform plan -out=phase2.plan

# 배포 실행
terraform apply phase2.plan

# 출력값 확인
echo "✅ 배포 완료!"
echo "API URL: $(terraform output -raw api_gateway_url)"
echo "Dashboard URL: $(terraform output -raw cloudfront_url)"
```

#### 체크리스트
- [ ] 배포 스크립트 실행 권한 설정
- [ ] 에러 처리 로직 추가
- [ ] 출력값 표시 기능
- [ ] 롤백 스크립트 준비

### 5단계: 통합 테스트 (75분)
#### 작업 내용
- [ ] API 엔드포인트 테스트
- [ ] CORS 동작 확인
- [ ] Lambda 함수 연결 테스트
- [ ] 정적 파일 호스팅 테스트

#### 테스트 체크리스트
```bash
# API 엔드포인트 테스트
curl -X POST https://api-url/api/events \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

curl -X GET https://api-url/api/realtime

curl -X GET https://api-url/api/stats

# CORS 테스트
curl -X OPTIONS https://api-url/api/events \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST"
```

#### 체크리스트
- [ ] 모든 API 엔드포인트 200 응답
- [ ] CORS 헤더 정상 반환
- [ ] Lambda 함수 로그 정상 출력
- [ ] CloudFront 도메인 접근 가능

## 🤝 담당자 B 협업 포인트

### 6시간 체크포인트
**목적**: API 엔드포인트 경로 최종 확정
**협의 내용**:
- API 경로 변경 요청 여부 (`/api/events` vs `/events`)
- 추가 엔드포인트 필요 여부
- 요청/응답 형식 확인

### 8시간 체크포인트
**목적**: Lambda 배포 환경 준비 완료 알림
**전달 사항**:
- API Gateway URL 공유
- Lambda 함수명 및 핸들러 경로 안내
- 배포 방법 가이드 제공

### 12시간 완료 시점
**목적**: 통합 테스트 요청
**협업 내용**:
- 담당자 B 코드 배포 지원
- API 연결 테스트 공동 진행
- 이슈 발생 시 즉시 해결

## 🚨 리스크 및 대응

### 주요 리스크
1. **API Gateway CORS 문제**
   - 대응: 와일드카드(*) 허용으로 우선 해결
   - 백업: AWS 콘솔에서 수동 설정

2. **Lambda 통합 실패**
   - 대응: 더미 응답으로 API 구조 먼저 완성
   - 백업: 프록시 통합 대신 Lambda 프록시 통합 사용

3. **CloudFront 배포 지연**
   - 대응: S3 직접 접근으로 임시 해결
   - 백업: Phase 3에서 CloudFront 완성

### 긴급 대응 스크립트
```bash
# API Gateway 수동 CORS 설정
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE

# Lambda 함수 수동 업데이트
aws lambda update-function-code \
  --function-name liveinsight-event-collector-dev \
  --zip-file fileb://dummy.zip
```

## 📊 성공 지표

### 기술적 목표
- [ ] API Gateway 3개 엔드포인트 정상 동작
- [ ] CORS 설정 완료 및 테스트 통과
- [ ] S3 + CloudFront 정적 호스팅 동작
- [ ] 모니터링 알람 정상 설정

### 협업 목표
- [ ] 담당자 B 코드 배포 환경 완성
- [ ] API 연결 테스트 성공
- [ ] 통합 개발 환경 구축 완료

## 🔄 Phase 2 완료 기준
- ✅ API Gateway 완전 구현 및 테스트 통과
- ✅ S3 + CloudFront 정적 호스팅 동작
- ✅ 모든 Lambda 함수 API 연결 완료
- ✅ CORS 설정 완료 및 브라우저 테스트 통과
- ✅ 담당자 B와 통합 테스트 성공

**Phase 2 완료 시 Phase 3 (성능 최적화)로 진행!** 🚀