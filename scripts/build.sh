#!/bin/bash
# LiveInsight 빌드 스크립트
set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo -e "${BLUE}"
echo "🔨 LiveInsight 빌드 시작..."
echo "=========================="
echo -e "${NC}"

# Lambda 더미 코드 압축
log_info "Lambda 더미 코드 압축 중..."
cd lambda_dummy
zip -r ../terraform/lambda_dummy.zip dummy.py
cd ..

log_success "Lambda 코드 압축 완료"

# Terraform 형식 검사
log_info "Terraform 코드 형식 검사 중..."
cd terraform
terraform fmt -check=true || {
    log_info "Terraform 코드 형식을 자동 수정합니다..."
    terraform fmt
}
cd ..

log_success "Terraform 코드 형식 검사 완료"

# Terraform 유효성 검사
log_info "Terraform 유효성 검사 중..."
cd terraform
terraform init -backend=false
terraform validate
cd ..

log_success "Terraform 유효성 검사 완료"

echo ""
log_success "빌드 완료! 🎉"
echo ""
echo "다음 명령어로 배포를 진행하세요:"
echo "  ./scripts/deploy.sh"