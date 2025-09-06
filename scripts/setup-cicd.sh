#!/bin/bash

# CI/CD 초기 설정 스크립트

echo "🚀 LiveInsight CI/CD 설정 시작..."

# Phase 1: IAM 사용자 생성
echo "📋 Phase 1: IAM 권한 설정"

# GitHub Actions용 IAM 사용자 생성
echo "1. IAM 사용자 생성 중..."
aws iam create-user --user-name github-actions-liveinsight 2>/dev/null || echo "사용자가 이미 존재합니다."

# 필요한 정책 연결
echo "2. IAM 정책 연결 중..."
aws iam attach-user-policy \
    --user-name github-actions-liveinsight \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-user-policy \
    --user-name github-actions-liveinsight \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

# 액세스 키 생성
echo "3. 액세스 키 생성 중..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name github-actions-liveinsight 2>/dev/null)

if [ $? -eq 0 ]; then
    ACCESS_KEY_ID=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId')
    SECRET_ACCESS_KEY=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey')
    
    echo "✅ 액세스 키 생성 완료!"
    echo "📝 GitHub Secrets에 다음 값들을 추가하세요:"
    echo "AWS_ACCESS_KEY_ID: $ACCESS_KEY_ID"
    echo "AWS_SECRET_ACCESS_KEY: $SECRET_ACCESS_KEY"
    echo "AWS_ACCOUNT_ID: $(aws sts get-caller-identity --query Account --output text)"
else
    echo "⚠️ 액세스 키가 이미 존재하거나 생성에 실패했습니다."
fi

echo "✅ Phase 1 완료!"