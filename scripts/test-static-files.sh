#!/bin/bash
set -e

echo "🧪 정적 파일 배포 테스트"

# S3 버킷 이름 가져오기
cd infrastructure
STATIC_BUCKET=$(terraform output -raw static_files_bucket 2>/dev/null || echo "")
cd ..

if [ -z "$STATIC_BUCKET" ]; then
    echo "❌ S3 버킷을 찾을 수 없습니다."
    exit 1
fi

echo "📦 S3 버킷: $STATIC_BUCKET"

# 정적 파일 URL 테스트
BASE_URL="https://$STATIC_BUCKET.s3.us-east-1.amazonaws.com/static"

echo "🔍 정적 파일 접근성 테스트..."

# CSS 파일 테스트
echo "  - CSS 파일 테스트..."
if curl -f -s "$BASE_URL/css/toss-style.css" > /dev/null; then
    echo "    ✅ toss-style.css 접근 가능"
else
    echo "    ❌ toss-style.css 접근 불가"
fi

# JS 파일 테스트
echo "  - JS 파일 테스트..."
if curl -f -s "$BASE_URL/js/toss-dashboard.js" > /dev/null; then
    echo "    ✅ toss-dashboard.js 접근 가능"
else
    echo "    ❌ toss-dashboard.js 접근 불가"
fi

if curl -f -s "$BASE_URL/js/realtime-dashboard.js" > /dev/null; then
    echo "    ✅ realtime-dashboard.js 접근 가능"
else
    echo "    ❌ realtime-dashboard.js 접근 불가"
fi

# 웹 애플리케이션 URL 가져오기
cd infrastructure/web-app
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
cd ../..

if [ -n "$ALB_DNS" ]; then
    echo "🌐 웹 애플리케이션 테스트: http://$ALB_DNS"
    
    # 대시보드 페이지 테스트
    if curl -f -s "http://$ALB_DNS/" > /dev/null; then
        echo "    ✅ 대시보드 페이지 접근 가능"
        
        # HTML에서 정적 파일 참조 확인
        HTML_CONTENT=$(curl -s "http://$ALB_DNS/")
        if echo "$HTML_CONTENT" | grep -q "$BASE_URL"; then
            echo "    ✅ HTML에서 S3 정적 파일 URL 참조 확인"
        else
            echo "    ❌ HTML에서 S3 정적 파일 URL 참조 없음"
        fi
    else
        echo "    ❌ 대시보드 페이지 접근 불가"
    fi
fi

echo "🏁 테스트 완료"