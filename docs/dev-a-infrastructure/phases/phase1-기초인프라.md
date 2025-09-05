# Phase 1: 기초 인프라 설정 (0-4시간)

## 🎯 Phase 목표
- DynamoDB 테이블 2개 생성
- IAM 역할 및 정책 설정
- Lambda 함수 기본 구조 준비
- 담당자 B 로컬 개발 환경 지원

## ⏰ 세부 작업 일정

### 1단계: Terraform 기본 설정 (30분)
#### 작업 내용
- [x] 프로젝트 디렉토리 구조 생성
- [ ] `terraform/main.tf` - Provider 설정
- [ ] `terraform/variables.tf` - 변수 정의
- [ ] `terraform/outputs.tf` - 출력값 정의

#### 체크리스트
- [ ] AWS Provider 5.0 설정 완료
- [ ] 기본 태그 정책 적용
- [ ] 변수 기본값 설정 (region: ap-northeast-2, env: dev)

### 2단계: DynamoDB 테이블 생성 (45분)
#### 작업 내용
- [ ] `terraform/dynamodb.tf` 생성
- [ ] Events 테이블 스키마 구현
- [ ] Sessions 테이블 스키마 구현
- [ ] GSI 인덱스 설정
- [ ] TTL 설정 (Events 테이블)

#### Events 테이블 스펙
```hcl
resource "aws_dynamodb_table" "events" {
  name           = "liveinsight-events-dev"
  billing_mode   = "ON_DEMAND"
  hash_key       = "session_id"
  range_key      = "timestamp"
  
  # TTL 24시간
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}
```

#### Sessions 테이블 스펙
```hcl
resource "aws_dynamodb_table" "sessions" {
  name           = "liveinsight-sessions-dev"
  billing_mode   = "ON_DEMAND"
  hash_key       = "session_id"
  
  # 활성 세션 조회용 GSI
  global_secondary_index {
    name     = "ActivityIndex"
    hash_key = "is_active"
    range_key = "last_activity"
  }
}
```

#### 체크리스트
- [ ] 테이블명 네이밍 규칙 준수
- [ ] GSI 설정 완료
- [ ] TTL 설정 테스트
- [ ] 태그 설정 완료

### 3단계: IAM 역할 및 정책 (45분)
#### 작업 내용
- [ ] `terraform/iam.tf` 생성
- [ ] Lambda 실행 역할 생성
- [ ] DynamoDB 접근 정책 생성
- [ ] CloudWatch 로그 권한 추가

#### IAM 역할 스펙
```hcl
resource "aws_iam_role" "lambda_role" {
  name = "liveinsight-lambda-role-dev"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
```

#### 체크리스트
- [ ] Lambda 기본 실행 권한 연결
- [ ] DynamoDB 읽기/쓰기 권한 설정
- [ ] CloudWatch 로그 권한 설정
- [ ] 최소 권한 원칙 준수

### 4단계: Lambda 함수 기본 구조 (60분)
#### 작업 내용
- [ ] `terraform/lambda.tf` 생성
- [ ] 3개 Lambda 함수 정의
- [ ] 환경변수 설정
- [ ] 더미 코드로 초기 배포

#### Lambda 함수 목록
1. **event-collector**: POST /api/events (Phase 3에서 512MB로 최적화 예정)
2. **realtime-api**: GET /api/realtime
3. **stats-api**: GET /api/stats

#### 환경변수 설정
```hcl
environment {
  variables = {
    EVENTS_TABLE   = aws_dynamodb_table.events.name
    SESSIONS_TABLE = aws_dynamodb_table.sessions.name
    AWS_REGION     = var.aws_region
  }
}
```

#### 체크리스트
- [ ] 3개 Lambda 함수 생성 완료
- [ ] 환경변수 설정 완료
- [ ] IAM 역할 연결 완료
- [ ] 더미 코드 배포 성공

### 5단계: 초기 배포 및 검증 (30분)
#### 작업 내용
- [ ] `terraform init` 실행
- [ ] `terraform plan` 검증
- [ ] `terraform apply` 배포
- [ ] AWS 콘솔에서 리소스 확인

#### 검증 체크리스트
- [ ] DynamoDB 테이블 2개 생성 확인
- [ ] Lambda 함수 3개 생성 확인
- [ ] IAM 역할 정상 연결 확인
- [ ] 환경변수 설정 확인

## 🤝 담당자 B 협업 포인트

### 2시간 체크포인트
**목적**: DynamoDB 스키마 최종 확정
**협의 내용**:
- Events 테이블 필드 추가 요청 여부
- Sessions 테이블 GSI 추가 요구사항
- 환경변수 네이밍 규칙 확인

**결정 기준**:
- 변경 없으면 현재 스키마 확정
- 변경 있으면 즉시 반영 후 재배포

### 4시간 완료 시점
**전달 사항**:
- DynamoDB 테이블명 공유
- 환경변수 목록 공유
- 로컬 개발 가이드 제공

## 🚨 리스크 및 대응

### 주요 리스크
1. **DynamoDB 스키마 변경 요청**
   - 대응: 2시간 내 변경 가능, 이후 Phase 2에서 처리

2. **Lambda 배포 실패**
   - 대응: 더미 함수로 우선 배포, 인프라 먼저 완성

3. **IAM 권한 문제**
   - 대응: 관리자 권한으로 임시 해결, 이후 최소 권한으로 조정

### 긴급 대응
```bash
# 빠른 상태 확인
terraform state list
aws dynamodb list-tables
aws lambda list-functions

# 롤백 (필요시)
terraform destroy -target=aws_lambda_function.event_collector
```

## 📊 성공 지표

### 기술적 목표
- [ ] terraform apply 에러 없이 완료
- [ ] 모든 리소스 정상 생성
- [ ] 환경변수 정상 설정

### 협업 목표
- [ ] 담당자 B 로컬 개발 환경 지원 완료
- [ ] DynamoDB 스키마 합의 완료
- [ ] Phase 2 진행 조건 충족

## 🔄 Phase 1 완료 기준
- ✅ DynamoDB 테이블 2개 정상 동작
- ✅ Lambda 함수 3개 배포 완료
- ✅ IAM 권한 정상 설정
- ✅ 담당자 B와 스키마 합의 완료
- ✅ terraform 상태 안정화

**Phase 1 완료 시 즉시 Phase 2로 진행!** 🚀