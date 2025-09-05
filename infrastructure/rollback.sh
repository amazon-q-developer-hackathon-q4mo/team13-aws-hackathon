#!/bin/bash
# LiveInsight 롤백 스크립트

set -e

echo "🔄 LiveInsight 롤백 시작..."

# 환경 변수 확인
if [ -z "$AWS_DEFAULT_REGION" ]; then
    export AWS_DEFAULT_REGION=us-east-1
fi

echo "📍 리전: $AWS_DEFAULT_REGION"

# 현재 Lambda 버전 확인
echo "📋 현재 Lambda 함수 상태 확인..."
aws lambda get-function --function-name LiveInsight-EventCollector \
  --query 'Configuration.{Version:Version,LastModified:LastModified}'

# 알람 비활성화 (선택사항)
echo "🔕 알람 임시 비활성화..."
aws cloudwatch disable-alarm-actions \
  --alarm-names "LiveInsight-Lambda-ErrorRate" "LiveInsight-Lambda-Duration" "LiveInsight-DynamoDB-Throttles"

# 이전 버전으로 롤백 (수동으로 버전 지정 필요)
if [ ! -z "$1" ]; then
    echo "⏪ Lambda 함수를 버전 $1로 롤백..."
    aws lambda update-function-code \
      --function-name LiveInsight-EventCollector \
      --zip-file fileb://lambda_function_backup.zip
else
    echo "⚠️ 롤백할 버전이 지정되지 않았습니다."
    echo "사용법: ./rollback.sh [backup_version]"
fi

# Terraform 상태 확인
echo "🏗️ Terraform 상태 확인..."
terraform plan

# 롤백 검증
echo "✅ 롤백 검증..."
aws lambda invoke \
  --function-name LiveInsight-EventCollector \
  --payload '{"httpMethod":"OPTIONS"}' \
  response.json

if grep -q "200" response.json; then
    echo "✅ 롤백 성공 - Lambda 함수 정상 동작"
else
    echo "❌ 롤백 실패 - Lambda 함수 오류"
    cat response.json
fi

# 알람 재활성화
echo "🔔 알람 재활성화..."
aws cloudwatch enable-alarm-actions \
  --alarm-names "LiveInsight-Lambda-ErrorRate" "LiveInsight-Lambda-Duration" "LiveInsight-DynamoDB-Throttles"

echo "🔄 롤백 완료!"

# 정리
rm -f response.json