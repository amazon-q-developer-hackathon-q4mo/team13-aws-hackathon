#!/bin/bash
set -e

# 설정
PROJECT_NAME="liveinsight"
AWS_REGION="us-east-1"

echo "🔄 Rolling back ECS deployment..."

cd infrastructure/web-app

# Terraform 출력에서 클러스터 및 서비스 정보 가져오기
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)

cd ../..

# 현재 실행 중인 태스크 정의 가져오기
CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $AWS_REGION \
    --query 'services[0].taskDefinition' \
    --output text)

echo "📋 Current task definition: $CURRENT_TASK_DEF"

# 태스크 정의 히스토리 가져오기
TASK_FAMILY=$(echo $CURRENT_TASK_DEF | cut -d'/' -f2 | cut -d':' -f1)
CURRENT_REVISION=$(echo $CURRENT_TASK_DEF | cut -d':' -f2)

if [ "$CURRENT_REVISION" -le 1 ]; then
    echo "❌ Cannot rollback. This is the first revision."
    exit 1
fi

PREVIOUS_REVISION=$((CURRENT_REVISION - 1))
PREVIOUS_TASK_DEF="$TASK_FAMILY:$PREVIOUS_REVISION"

echo "⏪ Rolling back to: $PREVIOUS_TASK_DEF"

# 서비스 업데이트
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $PREVIOUS_TASK_DEF \
    --region $AWS_REGION

# 롤백 완료 대기
echo "⏳ Waiting for rollback to complete..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $AWS_REGION

echo "✅ Rollback completed successfully!"

# 헬스체크
ALB_DNS=$(cd infrastructure/web-app && terraform output -raw alb_dns_name)
echo "🏥 Checking application health..."
sleep 30
if curl -f "http://$ALB_DNS/health/" > /dev/null 2>&1; then
    echo "✅ Health check passed after rollback!"
else
    echo "⚠️  Health check failed after rollback. Please investigate."
fi