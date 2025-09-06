#!/bin/bash
set -e

# Phase 8 배포 스크립트
ENVIRONMENT=${1:-prod}
DOMAIN_NAME=${2:-liveinsight-demo.com}

echo "🚀 Phase 8 배포 시작: $ENVIRONMENT 환경"
echo "📍 도메인: $DOMAIN_NAME"

# 사전 요구사항 확인
echo "🔍 사전 요구사항 확인..."

# AWS CLI 확인
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI가 설치되지 않았습니다"
    exit 1
fi

# Terraform 확인
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform이 설치되지 않았습니다"
    exit 1
fi

# AWS 자격 증명 확인
aws sts get-caller-identity > /dev/null || {
    echo "❌ AWS 자격 증명이 설정되지 않았습니다"
    exit 1
}

# Phase 6 배포 확인 (ALB 필요)
echo "🔍 Phase 6 배포 상태 확인..."
cd infrastructure/web-app
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
if [ -z "$ALB_DNS" ]; then
    echo "❌ Phase 6 (웹 애플리케이션)이 배포되지 않았습니다"
    echo "   먼저 ./scripts/deploy.sh를 실행하세요"
    exit 1
fi
echo "✅ ALB 확인: $ALB_DNS"

cd ../../

# Phase 8 배포 시작
echo "🏗️ Phase 8 인프라 배포 시작..."
cd infrastructure

# Terraform 변수 파일 생성
cat > phase8.tfvars << EOF
aws_region = "us-east-1"
project_name = "liveinsight"
environment = "$ENVIRONMENT"
domain_name = "$DOMAIN_NAME"
enable_waf = true
enable_guardduty = true
rate_limit = 2000
blocked_countries = []
EOF

echo "📋 배포 설정:"
cat phase8.tfvars

# 1. DNS 모듈 배포
echo "🌐 1/4: DNS 설정 배포..."
cd dns
terraform init -upgrade
terraform plan -var-file=../phase8.tfvars
terraform apply -var-file=../phase8.tfvars -auto-approve

ZONE_ID=$(terraform output -raw zone_id)
NAME_SERVERS=$(terraform output -json name_servers | jq -r '.[]' | tr '\n' ' ')

echo "✅ DNS 배포 완료"
echo "📍 Zone ID: $ZONE_ID"
echo "📍 Name Servers: $NAME_SERVERS"
echo ""
echo "⚠️  중요: 도메인 등록업체에서 네임서버를 다음으로 변경하세요:"
echo "$NAME_SERVERS"
echo ""

cd ../

# 2. SSL 인증서 배포
echo "🔒 2/4: SSL 인증서 배포..."
cd ssl
terraform init -upgrade
terraform plan -var-file=../phase8.tfvars
terraform apply -var-file=../phase8.tfvars -auto-approve

CERT_ARN=$(terraform output -raw certificate_arn)
echo "✅ SSL 인증서 배포 완료: $CERT_ARN"

cd ../

# 3. CDN 배포
echo "🌍 3/4: CloudFront CDN 배포..."
cd cdn
terraform init -upgrade
terraform plan -var-file=../phase8.tfvars
terraform apply -var-file=../phase8.tfvars -auto-approve

CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id)
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)
echo "✅ CDN 배포 완료"
echo "📍 Distribution ID: $CLOUDFRONT_ID"
echo "📍 CloudFront Domain: $CLOUDFRONT_DOMAIN"

cd ../

# 4. 보안 설정 배포
echo "🛡️ 4/4: 보안 설정 배포..."
cd security
terraform init -upgrade
terraform plan -var-file=../phase8.tfvars -var="cloudfront_distribution_id=$CLOUDFRONT_ID"
terraform apply -var-file=../phase8.tfvars -var="cloudfront_distribution_id=$CLOUDFRONT_ID" -auto-approve

WAF_ID=$(terraform output -raw waf_web_acl_id)
GUARDDUTY_ID=$(terraform output -raw guardduty_detector_id)
echo "✅ 보안 설정 배포 완료"
echo "📍 WAF Web ACL: $WAF_ID"
echo "📍 GuardDuty Detector: $GUARDDUTY_ID"

cd ../

# 통합 설정 배포
echo "🔧 통합 환경 설정 배포..."
terraform init -upgrade
terraform plan -var-file=phase8.tfvars
terraform apply -var-file=phase8.tfvars -auto-approve

echo ""
echo "🎉 Phase 8 배포 완료!"
echo "================================================"

# 배포 결과 출력
terraform output -json > phase8_outputs.json

echo "📊 배포 결과:"
echo "🌐 메인 사이트: https://$DOMAIN_NAME"
echo "🌐 WWW 사이트: https://www.$DOMAIN_NAME"
echo "🔌 API 엔드포인트: https://api.$DOMAIN_NAME"
echo "📊 대시보드: https://dashboard.$DOMAIN_NAME"
echo "⚙️ 관리자: https://admin.$DOMAIN_NAME"
echo "📜 JS 트래커: https://$DOMAIN_NAME/js/liveinsight-tracker.js"

echo ""
echo "🔒 보안 기능:"
echo "✅ SSL/TLS 인증서 (A+ 등급 목표)"
echo "✅ WAF 웹 애플리케이션 방화벽"
echo "✅ CloudFront CDN 글로벌 배포"
echo "✅ GuardDuty 위협 탐지"
echo "✅ VPC Flow Logs"

echo ""
echo "📋 다음 단계:"
echo "1. 도메인 네임서버 변경: $NAME_SERVERS"
echo "2. DNS 전파 대기 (최대 48시간)"
echo "3. SSL 인증서 검증 완료 대기 (5-10분)"
echo "4. CloudFront 배포 완료 대기 (15-20분)"

echo ""
echo "🧪 배포 검증:"
echo "./scripts/test-phase8.sh $ENVIRONMENT $DOMAIN_NAME"

cd ../