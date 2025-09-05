#!/bin/bash
# LiveInsight 배포 스크립트

set -e

echo "🚀 LiveInsight 배포 시작..."

# 환경 변수 확인
if [ -z "$AWS_DEFAULT_REGION" ]; then
    export AWS_DEFAULT_REGION=us-east-1
fi

echo "📍 리전: $AWS_DEFAULT_REGION"

# Terraform 배포
echo "🏗️ Terraform 인프라 배포..."
terraform init
terraform plan
terraform apply -auto-approve

# Lambda 함수 코드 업데이트
echo "⚡ Lambda 함수 업데이트..."
zip -f lambda_function.zip lambda_function.py
aws lambda update-function-code \
  --function-name LiveInsight-EventCollector \
  --zip-file fileb://lambda_function.zip

# 배포 검증
echo "✅ 배포 검증..."
aws lambda invoke \
  --function-name LiveInsight-EventCollector \
  --payload '{"httpMethod":"OPTIONS"}' \
  response.json

if grep -q "200" response.json; then
    echo "✅ Lambda 함수 정상 동작 확인"
else
    echo "❌ Lambda 함수 오류 발생"
    cat response.json
    exit 1
fi

# API Gateway 테스트
echo "🌐 API Gateway 테스트..."
API_URL=$(terraform output -raw api_gateway_url)
curl -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"deploy_test","event_type":"page_view","page_url":"https://example.com/deploy-test"}' \
  -w "\nHTTP Status: %{http_code}\n"

echo "🎉 배포 완료!"
echo "📊 API Gateway URL: $API_URL"
echo "📈 CloudWatch 대시보드: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_DEFAULT_REGION#dashboards:"

# 정리
rm -f response.json