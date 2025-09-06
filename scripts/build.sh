#!/bin/bash
set -e

# 설정
PROJECT_NAME="liveinsight"
AWS_REGION="us-east-1"
IMAGE_TAG=${1:-latest}

echo "🚀 Building and pushing Docker image..."

# AWS CLI 로그인 확인
aws sts get-caller-identity > /dev/null || {
    echo "❌ AWS CLI not configured. Please run 'aws configure'"
    exit 1
}

# ECR 로그인
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com

# ECR 리포지토리 URL 가져오기
ECR_REPO=$(aws ecr describe-repositories --repository-names $PROJECT_NAME-app --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")

if [ -z "$ECR_REPO" ]; then
    echo "❌ ECR repository not found. Please deploy infrastructure first."
    exit 1
fi

echo "📦 Building Docker image for linux/amd64..."
# src 디렉토리 존재 확인
if [ ! -d "src" ]; then
    echo "❌ src directory not found. Please ensure Django code is in src/"
    exit 1
fi

# src 디렉토리에서 빌드 (linux/amd64 플랫폼 명시)
cd src
docker build --platform linux/amd64 -t $PROJECT_NAME:$IMAGE_TAG .
cd ..

echo "🏷️  Tagging image..."
docker tag $PROJECT_NAME:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG
docker tag $PROJECT_NAME:$IMAGE_TAG $ECR_REPO:latest

echo "⬆️  Pushing to ECR..."
docker push $ECR_REPO:$IMAGE_TAG
docker push $ECR_REPO:latest

echo "✅ Build and push completed successfully!"
echo "📍 Image: $ECR_REPO:$IMAGE_TAG"