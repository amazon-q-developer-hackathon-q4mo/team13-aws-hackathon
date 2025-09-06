#!/bin/bash
set -e

echo "🚀 Starting Django application..."

# 정적 파일 수집
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

# S3에 정적 파일 업로드 (버킷이 설정된 경우)
if [ -n "$STATIC_FILES_BUCKET" ]; then
    echo "☁️ Uploading static files to S3..."
    aws s3 sync staticfiles/ s3://$STATIC_FILES_BUCKET/static/ --delete
    echo "✅ Static files uploaded to S3"
fi

# Django 애플리케이션 시작
echo "🌐 Starting Gunicorn server..."
exec gunicorn --bind 0.0.0.0:8000 --workers 2 liveinsight.wsgi:application