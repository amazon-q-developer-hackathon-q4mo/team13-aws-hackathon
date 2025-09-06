#!/bin/bash
# LiveInsight 전체 시스템 배포 스크립트 (DynamoDB + Django 웹앱 통합)

set -e

echo "🚀 LiveInsight 전체 시스템 배포 시작..."

# 환경 변수 확인
if [ -z "$AWS_DEFAULT_REGION" ]; then
    export AWS_DEFAULT_REGION=us-east-1
fi

echo "📍 리전: $AWS_DEFAULT_REGION"

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."

# Terraform 배포 (DynamoDB + Django 웹앱 통합)
echo "🏗️ Terraform 통합 인프라 배포..."
cd infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# Lambda 함수 코드 업데이트
echo "⚡ Lambda 함수 업데이트..."
zip -f lambda_function.zip lambda_function.py
aws lambda update-function-code \
  --function-name LiveInsight-EventCollector \
  --zip-file fileb://lambda_function.zip

# 배포 결과 출력
echo "✅ 배포 완료!"
echo "📊 배포된 리소스:"
terraform output

echo ""
echo "🌐 대시보드 URL:"
echo "- Django 웹앱: $(terraform output -raw web_app_url)"
echo "- Django 대시보드: $(terraform output -raw web_app_dashboard_url)" 
echo "- CloudWatch 대시보드: $(terraform output -raw cloudwatch_dashboard_url)"
echo "- API Gateway: $(terraform output -raw api_gateway_url)"

echo ""
echo "🎉 LiveInsight 전체 시스템 배포 완료!"