#!/bin/bash

# S3에 정적 파일 업로드 스크립트

if [ -z "$STATIC_FILES_BUCKET" ]; then
    echo "STATIC_FILES_BUCKET 환경변수가 설정되지 않았습니다."
    exit 0
fi

echo "정적 파일을 S3 버킷 $STATIC_FILES_BUCKET 에 업로드 중..."

# Django collectstatic 실행
python manage.py collectstatic --noinput

# AWS CLI를 사용하여 S3에 업로드
if command -v aws &> /dev/null; then
    aws s3 sync staticfiles/ s3://$STATIC_FILES_BUCKET/static/ --delete
    echo "정적 파일 업로드 완료"
else
    # Django 관리 명령어 사용
    python manage.py collectstatic_s3
fi