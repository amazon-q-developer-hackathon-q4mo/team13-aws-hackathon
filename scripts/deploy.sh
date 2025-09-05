#!/bin/bash
# LiveInsight Phase 2 배포 스크립트
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 에러 처리
error_exit() {
    log_error "$1"
    exit 1
}

# 시작 메시지
echo -e "${BLUE}"
echo "🚀 LiveInsight Phase 2 배포 시작..."
echo "=================================="
echo -e "${NC}"

# 환경 변수 확인
if [ -z "$AWS_PROFILE" ]; then
    log_warning "AWS_PROFILE이 설정되지 않았습니다. 기본 프로필을 사용합니다."
else
    log_info "AWS Profile: $AWS_PROFILE"
fi

# AWS 계정 확인
log_info "AWS 계정 정보 확인 중..."
aws sts get-caller-identity || error_exit "AWS 자격 증명을 확인할 수 없습니다."

# Terraform 디렉토리로 이동
cd terraform || error_exit "terraform 디렉토리를 찾을 수 없습니다."

# Terraform 초기화
log_info "Terraform 초기화 중..."
terraform init || error_exit "Terraform 초기화에 실패했습니다."

# Terraform 계획 생성
log_info "Terraform 계획 생성 중..."
terraform plan -var="aws_region=us-east-1" -out=phase2.plan || error_exit "Terraform 계획 생성에 실패했습니다."

# 사용자 확인
echo ""
log_warning "위의 계획을 검토하고 배포를 진행하시겠습니까? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "배포가 취소되었습니다."
    rm -f phase2.plan
    exit 0
fi

# Terraform 적용
log_info "Terraform 배포 실행 중..."
terraform apply phase2.plan || error_exit "Terraform 배포에 실패했습니다."

# 계획 파일 정리
rm -f phase2.plan

# 출력값 확인
log_info "배포 결과 확인 중..."
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "N/A")
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "N/A")
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "N/A")

# 성공 메시지
echo ""
echo -e "${GREEN}"
echo "🎉 Phase 2 배포 완료!"
echo "===================="
echo -e "${NC}"

log_success "API Gateway URL: $API_URL"
log_success "Dashboard URL: $CLOUDFRONT_URL"
log_success "S3 Bucket: $S3_BUCKET"

# 헬스체크
echo ""
log_info "헬스체크 실행 중..."

if [ "$API_URL" != "N/A" ]; then
    # API 엔드포인트 테스트
    log_info "API 엔드포인트 테스트 중..."
    
    # /api/stats 테스트 (GET 요청)
    if curl -s -f -X GET "$API_URL/api/stats" > /dev/null; then
        log_success "GET /api/stats - 정상"
    else
        log_warning "GET /api/stats - 응답 없음 (Lambda 코드 미구현 가능)"
    fi
    
    # /api/realtime 테스트 (GET 요청)
    if curl -s -f -X GET "$API_URL/api/realtime" > /dev/null; then
        log_success "GET /api/realtime - 정상"
    else
        log_warning "GET /api/realtime - 응답 없음 (Lambda 코드 미구현 가능)"
    fi
    
    # CORS 테스트
    CORS_RESPONSE=$(curl -s -I -X OPTIONS "$API_URL/api/stats" -H "Origin: https://example.com" | grep -i "access-control-allow-origin" || echo "")
    if [ -n "$CORS_RESPONSE" ]; then
        log_success "CORS 설정 - 정상"
    else
        log_warning "CORS 설정 - 확인 필요"
    fi
else
    log_warning "API URL을 가져올 수 없어 헬스체크를 건너뜁니다."
fi

# CloudFront 배포 상태 확인
if [ "$CLOUDFRONT_URL" != "N/A" ]; then
    log_info "CloudFront 배포 상태 확인 중..."
    if curl -s -f "$CLOUDFRONT_URL" > /dev/null; then
        log_success "CloudFront 배포 - 정상"
    else
        log_warning "CloudFront 배포 - 아직 전파 중일 수 있습니다 (최대 15분 소요)"
    fi
fi

# 다음 단계 안내
echo ""
echo -e "${BLUE}"
echo "📋 다음 단계:"
echo "============"
echo -e "${NC}"
echo "1. 담당자 B와 API 엔드포인트 공유"
echo "2. Lambda 함수 실제 코드 배포"
echo "3. 통합 테스트 진행"
echo "4. Phase 3 (성능 최적화) 준비"

echo ""
log_success "배포 스크립트 완료! 🎉"