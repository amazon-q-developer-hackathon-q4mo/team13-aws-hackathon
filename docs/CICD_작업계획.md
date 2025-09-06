# LiveInsight CI/CD 자동 배포 구성 계획

## 📋 프로젝트 개요

**목표**: main 브랜치 푸시 시 자동으로 ECS Fargate에 배포되는 CI/CD 파이프라인 구축

**현재 상태**: 수동 배포 (`./scripts/deploy-clean.sh`)
**목표 상태**: GitHub Actions 기반 자동 배포

## 🏗️ 아키텍처 설계

### CI/CD 파이프라인 구조
```
GitHub Repository (main branch)
    ↓ (push trigger)
GitHub Actions Workflow
    ↓
1. 코드 체크아웃
2. Docker 이미지 빌드
3. ECR 푸시
4. ECS 서비스 업데이트
5. 배포 검증
    ↓
ECS Fargate 서비스 자동 업데이트
```

### 필요한 AWS 리소스
- **기존 리소스**: ECS Cluster, ECR Repository, ALB
- **추가 필요**: IAM Role (GitHub Actions용)

## 📝 상세 작업 계획

### Phase 1: IAM 권한 설정 (30분)

#### 1.1 GitHub Actions용 IAM 사용자 생성
```bash
# AWS CLI로 IAM 사용자 생성
aws iam create-user --user-name github-actions-liveinsight

# 필요한 정책 연결
aws iam attach-user-policy \
    --user-name github-actions-liveinsight \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-user-policy \
    --user-name github-actions-liveinsight \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
```

#### 1.2 액세스 키 생성 및 GitHub Secrets 설정
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`

### Phase 2: GitHub Actions Workflow 작성 (45분)

#### 2.1 워크플로우 파일 생성
**파일**: `.github/workflows/deploy.yml`

```yaml
name: Deploy to ECS

on:
  push:
    branches: [ main ]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: liveinsight-app
  ECS_SERVICE: LiveInsight-service
  ECS_CLUSTER: LiveInsight-cluster

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag, and push image to Amazon ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        cd src
        docker build --platform linux/amd64 -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
        echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

    - name: Deploy to Amazon ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: task-definition.json
        service: ${{ env.ECS_SERVICE }}
        cluster: ${{ env.ECS_CLUSTER }}
        wait-for-service-stability: true
```

#### 2.2 ECS Task Definition 파일 생성
**파일**: `task-definition.json`

### Phase 3: 배포 검증 및 알림 설정 (30분)

#### 3.1 헬스체크 스크립트 추가
```bash
# 배포 후 자동 검증
curl -f http://LiveInsight-alb-552300943.us-east-1.elb.amazonaws.com/health/
```

#### 3.2 Slack 알림 설정 (선택사항)
- 배포 성공/실패 알림
- GitHub Actions 결과 전송

### Phase 4: 보안 강화 (15분)

#### 4.1 최소 권한 원칙 적용
- 커스텀 IAM 정책 생성
- 불필요한 권한 제거

#### 4.2 시크릿 관리
- GitHub Secrets 암호화
- AWS Systems Manager Parameter Store 활용

## 🛠️ 구현 파일 목록

### 1. GitHub Actions Workflow
```
.github/
└── workflows/
    └── deploy.yml          # 메인 배포 워크플로우
```

### 2. ECS Task Definition
```
task-definition.json        # ECS 태스크 정의
```

### 3. IAM 정책 파일
```
iam/
├── github-actions-policy.json    # 커스텀 IAM 정책
└── trust-policy.json            # 신뢰 정책
```

### 4. 스크립트 파일
```
scripts/
├── setup-cicd.sh          # CI/CD 초기 설정
├── verify-deployment.sh   # 배포 검증
└── rollback.sh            # 롤백 스크립트
```

## ⏱️ 예상 소요 시간

| Phase | 작업 내용 | 소요 시간 | 담당자 |
|-------|-----------|-----------|--------|
| 1 | IAM 권한 설정 | 30분 | DevOps |
| 2 | GitHub Actions 구성 | 45분 | DevOps |
| 3 | 배포 검증 설정 | 30분 | DevOps |
| 4 | 보안 강화 | 15분 | DevOps |
| **총계** | | **2시간** | |

## 🎯 성공 기준

### 기능적 요구사항
- ✅ main 브랜치 푸시 시 자동 배포 실행
- ✅ Docker 이미지 자동 빌드 및 ECR 푸시
- ✅ ECS 서비스 무중단 업데이트
- ✅ 배포 실패 시 자동 롤백

### 비기능적 요구사항
- ✅ 배포 시간: 5분 이내
- ✅ 성공률: 95% 이상
- ✅ 보안: 최소 권한 원칙 적용
- ✅ 모니터링: 배포 상태 실시간 추적

## 🔧 구현 단계

### 1단계: 환경 준비
```bash
# GitHub 리포지토리 클론
git clone https://github.com/your-org/team13-aws-hackathon.git
cd team13-aws-hackathon

# CI/CD 설정 스크립트 실행
chmod +x scripts/setup-cicd.sh
./scripts/setup-cicd.sh
```

### 2단계: GitHub Secrets 설정
1. GitHub 리포지토리 → Settings → Secrets and variables → Actions
2. 다음 시크릿 추가:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_ACCOUNT_ID`

### 3단계: 워크플로우 테스트
```bash
# 테스트 커밋 푸시
git add .
git commit -m "feat: CI/CD 파이프라인 구성"
git push origin main
```

### 4단계: 배포 검증
- GitHub Actions 탭에서 워크플로우 실행 확인
- ECS 서비스 업데이트 상태 모니터링
- 애플리케이션 헬스체크 수행

## 📊 모니터링 및 알림

### GitHub Actions 대시보드
- 워크플로우 실행 히스토리
- 빌드 시간 및 성공률 추적
- 실패 원인 분석

### AWS CloudWatch 통합
- ECS 서비스 메트릭 모니터링
- 배포 이벤트 로깅
- 알람 설정 (배포 실패 시)

### Slack 알림 (선택사항)
```yaml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    channel: '#deployments'
  if: always()
```

## 🚨 위험 요소 및 대응 방안

### 위험 요소
1. **배포 실패**: Docker 빌드 오류, ECR 푸시 실패
2. **서비스 다운타임**: ECS 업데이트 중 서비스 중단
3. **권한 문제**: IAM 권한 부족으로 배포 실패
4. **리소스 한계**: ECR 스토리지 용량 초과

### 대응 방안
1. **자동 롤백**: 배포 실패 시 이전 버전으로 자동 복구
2. **블루-그린 배포**: 무중단 배포 전략 적용
3. **권한 검증**: 배포 전 IAM 권한 사전 확인
4. **리소스 모니터링**: CloudWatch 알람으로 사전 감지

## 📈 향후 개선 계획

### Phase 2 확장 (추후)
- **멀티 환경 배포**: dev, staging, prod 환경 분리
- **승인 워크플로우**: 프로덕션 배포 시 수동 승인
- **자동 테스트**: 단위 테스트, 통합 테스트 자동 실행
- **성능 테스트**: 배포 후 자동 성능 검증

### 고급 기능
- **카나리 배포**: 점진적 트래픽 전환
- **자동 스케일링**: 트래픽 기반 인스턴스 조정
- **보안 스캔**: 컨테이너 이미지 취약점 검사
- **비용 최적화**: 리소스 사용량 기반 자동 조정

## 💰 예상 비용 영향

### 추가 비용
- **GitHub Actions**: 월 2,000분 무료 (초과 시 $0.008/분)
- **ECR 스토리지**: 이미지 버전 관리로 약 $2-5/월 추가
- **CloudWatch 로그**: 배포 로그 저장으로 약 $1-2/월 추가

### 비용 절약
- **수동 배포 시간 절약**: 개발자 시간 월 10시간 절약
- **배포 오류 감소**: 수동 실수로 인한 다운타임 방지
- **자동 롤백**: 장애 복구 시간 단축

**총 예상 추가 비용**: **$3-7/월**
**예상 절약 효과**: **개발 생산성 30% 향상**

이 계획서를 바탕으로 단계별로 CI/CD 파이프라인을 구축하면 안정적이고 효율적인 자동 배포 시스템을 완성할 수 있습니다.