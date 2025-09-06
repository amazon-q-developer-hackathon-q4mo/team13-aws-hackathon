#!/bin/bash

set -e

echo "🚀 JavaScript SDK 배포 시작..."

# Terraform 초기화 및 적용
cd infrastructure/js-sdk
terraform init
terraform apply -auto-approve

# SDK URL 출력
SDK_URL=$(terraform output -raw js_sdk_url)
echo "✅ JavaScript SDK 배포 완료!"
echo "📦 SDK URL: $SDK_URL"
echo ""
echo "사용 예시:"
echo "<script src=\"$SDK_URL\"></script>"
echo "<script>"
echo "  LiveInsight.init({"
echo "    apiUrl: 'YOUR_API_GATEWAY_URL'"
echo "  });"
echo "</script>"