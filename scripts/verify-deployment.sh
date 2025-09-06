#!/bin/bash

# 배포 검증 스크립트

echo "🔍 배포 검증 시작..."

ALB_URL="http://LiveInsight-alb-552300943.us-east-1.elb.amazonaws.com"

# 헬스체크
echo "1. 헬스체크 수행 중..."
for i in {1..10}; do
  if curl -f "$ALB_URL/health/" > /dev/null 2>&1; then
    echo "✅ 헬스체크 성공!"
    break
  else
    echo "⏳ 헬스체크 재시도 $i/10..."
    sleep 15
  fi
done

# API 엔드포인트 테스트
echo "2. API 엔드포인트 테스트 중..."
if curl -f "$ALB_URL/api/statistics/summary/" > /dev/null 2>&1; then
  echo "✅ API 엔드포인트 정상!"
else
  echo "❌ API 엔드포인트 오류"
  exit 1
fi

# ECS 서비스 상태 확인
echo "3. ECS 서비스 상태 확인 중..."
SERVICE_STATUS=$(aws ecs describe-services \
  --cluster LiveInsight-cluster \
  --services LiveInsight-service \
  --query 'services[0].status' \
  --output text)

if [ "$SERVICE_STATUS" = "ACTIVE" ]; then
  echo "✅ ECS 서비스 정상!"
else
  echo "❌ ECS 서비스 상태: $SERVICE_STATUS"
  exit 1
fi

echo "🎉 배포 검증 완료!"