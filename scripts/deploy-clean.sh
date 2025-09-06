#!/bin/bash

# 정리된 코드 배포 스크립트

echo "🧹 정리된 코드 배포 중..."

# Docker 이미지 빌드
cd src
docker build --platform linux/amd64 -t liveinsight-app:latest .

# ECR 푸시
cd ..
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/liveinsight-app"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

docker tag liveinsight-app:latest $ECR_URI:latest
docker push $ECR_URI:latest

# ECS 서비스 업데이트
aws ecs update-service \
    --cluster LiveInsight-cluster \
    --service LiveInsight-service \
    --force-new-deployment \
    --region us-east-1

echo "✅ 정리된 코드 배포 완료!"