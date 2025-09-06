#!/bin/bash
set -e

echo "📁 정적 파일을 S3에 업로드합니다..."

# Terraform에서 S3 버킷 이름 가져오기
cd infrastructure
STATIC_BUCKET=$(terraform output -raw static_files_bucket)
cd ..

if [ -z "$STATIC_BUCKET" ]; then
    echo "❌ S3 버킷을 찾을 수 없습니다."
    exit 1
fi

echo "📦 S3 버킷: $STATIC_BUCKET"

# Django 정적 파일 수집 및 업로드
cd src
export STATIC_FILES_BUCKET=$STATIC_BUCKET
export AWS_DEFAULT_REGION=us-east-1

# 정적 파일 수집
python manage.py collectstatic --noinput

# S3 업로드
if command -v aws &> /dev/null; then
    echo "🚀 AWS CLI로 업로드 중..."
    aws s3 sync staticfiles/ s3://$STATIC_BUCKET/static/ --delete
else
    echo "🚀 Django 명령어로 업로드 중..."
    python manage.py collectstatic_s3
fi

echo "✅ 정적 파일 업로드 완료!"
echo "🌐 정적 파일 URL: https://$STATIC_BUCKET.s3.us-east-1.amazonaws.com/static/"