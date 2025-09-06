# CI/CD 설정 가이드

## 🔐 GitHub Secrets 설정

GitHub 리포지토리에서 다음 Secrets를 설정해야 합니다:

### 1. Settings → Secrets and variables → Actions 이동

### 2. 다음 Secrets 추가:

```
AWS_ACCESS_KEY_ID: 현재 사용 중인 AWS Access Key ID
AWS_SECRET_ACCESS_KEY: 현재 사용 중인 AWS Secret Access Key  
AWS_ACCOUNT_ID: 730335341740
```

### 3. 현재 AWS 자격 증명 확인:
```bash
aws configure list
aws sts get-caller-identity
```

## 🚀 워크플로우 테스트

### 1. 코드 변경 후 푸시:
```bash
git add .
git commit -m "feat: CI/CD 파이프라인 구성"
git push origin main
```

### 2. GitHub Actions 탭에서 워크플로우 실행 확인

### 3. 배포 완료 후 확인:
```bash
curl http://LiveInsight-alb-552300943.us-east-1.elb.amazonaws.com/health/
```

## 📋 체크리스트

- [ ] GitHub Secrets 설정 완료
- [ ] 워크플로우 파일 커밋
- [ ] 첫 번째 자동 배포 테스트
- [ ] 배포 검증 스크립트 실행
- [ ] ECS 서비스 상태 확인

## 🔧 문제 해결

### 권한 오류 시:
- AWS 자격 증명 확인
- IAM 권한 검토

### 배포 실패 시:
- GitHub Actions 로그 확인
- ECS 서비스 이벤트 확인
- CloudWatch 로그 검토