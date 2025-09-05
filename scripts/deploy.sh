#!/bin/bash
set -e

# 설정
PROJECT_NAME="liveinsight"
AWS_REGION="us-east-1"
IMAGE_TAG=${1:-latest}

echo "🚀 Deploying to ECS..."

# 인프라 배포
echo "🏗️  Deploying infrastructure..."
cd infrastructure/web-app
terraform init
terraform plan
terraform apply -auto-approve

# ECR 리포지토리 URL 가져오기
ECR_REPO=$(terraform output -raw ecr_repository_url)
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)

cd ../..

# Docker 이미지 빌드 및 푸시
echo "📦 Building and pushing Docker image..."
./scripts/build.sh $IMAGE_TAG

# ECS 서비스 업데이트
echo "🔄 Updating ECS service..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force-new-deployment \
    --region $AWS_REGION

# 배포 상태 확인
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $AWS_REGION

# ALB DNS 이름 출력
ALB_DNS=$(cd infrastructure/web-app && terraform output -raw alb_dns_name)
echo "✅ Deployment completed successfully!"
echo "🌐 Application URL: http://$ALB_DNS"

# 헬스체크
echo "🏥 Checking application health..."
sleep 30
if curl -f "http://$ALB_DNS/health/" > /dev/null 2>&1; then
    echo "✅ Health check passed!"
else
    echo "⚠️  Health check failed. Please check the logs."
fi