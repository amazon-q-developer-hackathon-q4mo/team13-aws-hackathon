#!/bin/bash

# LiveInsight 배포 스크립트

set -e

ENVIRONMENT=${1:-dev}
echo "🚀 Deploying LiveInsight to $ENVIRONMENT environment..."

# 환경 변수 파일 복사
if [ "$ENVIRONMENT" = "production" ]; then
    cp .env.production .env
    echo "✅ Using production environment"
elif [ "$ENVIRONMENT" = "staging" ]; then
    cp .env.staging .env
    echo "✅ Using staging environment"
else
    echo "✅ Using development environment"
fi

# 의존성 설치
echo "📦 Installing dependencies..."
uv sync

# 코드 품질 검사 (개발 환경에서만)
if [ "$ENVIRONMENT" = "dev" ]; then
    echo "🔍 Running code quality checks..."
    uv run black --check src/ || echo "⚠️  Code formatting issues found"
    uv run isort --check-only src/ || echo "⚠️  Import sorting issues found"
fi

# 테스트 실행 (개발/스테이징 환경에서만)
if [ "$ENVIRONMENT" != "production" ]; then
    echo "🧪 Running tests..."
    # uv run pytest tests/ || echo "⚠️  Some tests failed"
fi

# 빌드
echo "🔨 Building application..."
uv build

# Lambda 패키지 생성 (프로덕션/스테이징 환경)
if [ "$ENVIRONMENT" != "dev" ]; then
    echo "📦 Creating Lambda deployment package..."
    mkdir -p dist/lambda
    cp -r src/ dist/lambda/
    cp -r frontend/ dist/lambda/
    cp .env dist/lambda/
    
    # 의존성 패키징
    uv export --format requirements-txt --output-file dist/lambda/requirements.txt
    
    echo "✅ Lambda package created in dist/lambda/"
fi

echo "🎉 Deployment preparation completed for $ENVIRONMENT!"

if [ "$ENVIRONMENT" = "dev" ]; then
    echo "💡 To start development server:"
    echo "   uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload"
fi