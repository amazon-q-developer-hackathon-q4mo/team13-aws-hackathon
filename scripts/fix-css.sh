#!/bin/bash

# CSS 문제 해결 스크립트

echo "🎨 CSS 문제 해결 중..."

# 1. Django 정적 파일 수집
cd src
python3 manage.py collectstatic --noinput

# 2. Docker 이미지 재빌드
cd ..
docker build --platform linux/amd64 -t liveinsight-app:latest ./src

# 3. ECR에 푸시
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/liveinsight-app"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

docker tag liveinsight-app:latest $ECR_URI:latest
docker push $ECR_URI:latest

# 4. ECS 서비스 업데이트
aws ecs update-service \
    --cluster LiveInsight-cluster \
    --service LiveInsight-service \
    --force-new-deployment \
    --region us-east-1

echo "✅ CSS 수정 완료! 2-3분 후 새로고침하세요."