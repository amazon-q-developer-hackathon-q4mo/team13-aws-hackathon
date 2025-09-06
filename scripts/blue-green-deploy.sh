#!/bin/bash
set -e

# 블루-그린 배포 스크립트
PROJECT_NAME="liveinsight"
AWS_REGION="us-east-1"
IMAGE_TAG=${1:-latest}

echo "🔵🟢 Starting Blue-Green deployment..."

cd infrastructure/web-app

# 현재 서비스 정보 가져오기
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
ECR_REPO=$(terraform output -raw ecr_repository_url)

cd ../..

# 1. 새 이미지 빌드 및 푸시
echo "📦 Building new image..."
./scripts/build.sh $IMAGE_TAG

# 2. 현재 태스크 정의 가져오기
echo "📋 Getting current task definition..."
CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $AWS_REGION \
    --query 'services[0].taskDefinition' \
    --output text)

TASK_FAMILY=$(echo $CURRENT_TASK_DEF | cut -d'/' -f2 | cut -d':' -f1)

# 3. 새 태스크 정의 생성
echo "🆕 Creating new task definition..."
NEW_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition $CURRENT_TASK_DEF \
    --region $AWS_REGION \
    --query 'taskDefinition' \
    --output json | \
    jq --arg IMAGE "$ECR_REPO:$IMAGE_TAG" \
    '.containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)')

NEW_REVISION=$(echo $NEW_TASK_DEF | aws ecs register-task-definition \
    --region $AWS_REGION \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.revision' \
    --output text)

NEW_TASK_DEF_ARN="$TASK_FAMILY:$NEW_REVISION"

echo "✅ New task definition created: $NEW_TASK_DEF_ARN"

# 4. 서비스 업데이트 (블루-그린)
echo "🔄 Updating service with new task definition..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $NEW_TASK_DEF_ARN \
    --region $AWS_REGION > /dev/null

# 5. 배포 완료 대기
echo "⏳ Waiting for deployment to stabilize..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $AWS_REGION

# 6. 헬스체크
echo "🏥 Running health checks..."
ALB_DNS=$(cd infrastructure/web-app && terraform output -raw alb_dns_name)
sleep 30

HEALTH_CHECK_PASSED=false
for i in {1..5}; do
    if curl -f "http://$ALB_DNS/health/" > /dev/null 2>&1; then
        echo "✅ Health check passed (attempt $i)"
        HEALTH_CHECK_PASSED=true
        break
    else
        echo "⚠️  Health check failed (attempt $i), retrying..."
        sleep 10
    fi
done

if [ "$HEALTH_CHECK_PASSED" = false ]; then
    echo "❌ Health checks failed, rolling back..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --task-definition $CURRENT_TASK_DEF \
        --region $AWS_REGION > /dev/null
    
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $AWS_REGION
    
    echo "🔄 Rollback completed"
    exit 1
fi

echo "🎉 Blue-Green deployment completed successfully!"
echo "🌐 Application URL: http://$ALB_DNS"