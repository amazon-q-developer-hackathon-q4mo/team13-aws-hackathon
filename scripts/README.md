# Scripts 사용 가이드

LiveInsight 프로젝트의 개발, 테스트, 배포를 위한 스크립트 모음입니다.

## 📋 스크립트 목록

### 🛠️ 개발 스크립트

#### `dev.sh` - 개발 환경 실행
Django 개발 서버를 네이티브 또는 Docker 환경에서 실행합니다.

```bash
# 네이티브 Django 서버 (권장)
./scripts/dev.sh native
./scripts/dev.sh n

# Docker Compose 환경
./scripts/dev.sh docker  
./scripts/dev.sh d
```

**접속 URL:**
- Django 앱: http://localhost:8000
- 대시보드: http://localhost:8000/
- API: http://localhost:8000/api/
- 헬스체크: http://localhost:8000/health/
- LocalStack (Docker 모드): http://localhost:4566

### 🧪 테스트 스크립트

#### `test.sh` - 테스트 실행
로컬 또는 배포된 애플리케이션을 테스트합니다.

```bash
# 로컬 Django 앱 테스트
./scripts/test.sh local
./scripts/test.sh l

# 배포된 앱 테스트
./scripts/test.sh deployment
./scripts/test.sh d
```

**테스트 항목:**
- Django 설정 검증
- 마이그레이션 상태 확인
- 정적 파일 수집 테스트
- 헬스체크 엔드포인트
- 대시보드 접근성

### 🚀 배포 스크립트

#### `build.sh` - Docker 이미지 빌드
Docker 이미지를 빌드하고 ECR에 푸시합니다.

```bash
# 최신 태그로 빌드
./scripts/build.sh

# 특정 태그로 빌드
./scripts/build.sh v1.0.0
```

**사전 요구사항:**
- AWS CLI 설정 완료
- ECR 리포지토리 존재 (deploy.sh로 생성)

#### `deploy.sh` - 전체 배포
인프라 배포부터 애플리케이션 배포까지 전체 과정을 자동화합니다.

```bash
# 전체 배포 (latest 태그)
./scripts/deploy.sh

# 특정 태그로 배포
./scripts/deploy.sh v1.0.0
```

**배포 과정:**
1. Terraform 인프라 배포
2. Docker 이미지 빌드 및 푸시
3. ECS 서비스 업데이트
4. 배포 완료 대기
5. 헬스체크 검증

#### `rollback.sh` - 배포 롤백
이전 버전으로 롤백합니다.

```bash
./scripts/rollback.sh
```

**롤백 과정:**
1. 현재 태스크 정의 확인
2. 이전 리비전으로 롤백
3. 서비스 안정화 대기
4. 헬스체크 검증

## 🔧 사전 요구사항

### 로컬 개발
- Python 3.11+
- uv 또는 pip
- Docker & Docker Compose (Docker 모드 사용시)

### AWS 배포
- AWS CLI 설치 및 설정
- Terraform 설치
- Docker 설치
- 적절한 AWS 권한 (ECS, ECR, VPC, IAM 등)

## 📝 사용 예시

### 일반적인 개발 워크플로우

```bash
# 1. 개발 서버 시작
./scripts/dev.sh native

# 2. 코드 변경 후 로컬 테스트
./scripts/test.sh local

# 3. AWS에 배포
./scripts/deploy.sh

# 4. 배포 검증
./scripts/test.sh deployment
```

### 문제 발생시 롤백

```bash
# 배포에 문제가 있을 경우
./scripts/rollback.sh
```

## ⚠️ 주의사항

- **AWS 비용**: 배포시 ECS Fargate, ALB, NAT Gateway 등의 비용이 발생합니다
- **권한**: AWS 리소스 생성을 위한 적절한 IAM 권한이 필요합니다
- **리전**: 기본 리전은 `us-east-1`입니다
- **정리**: 테스트 후 불필요한 리소스는 `terraform destroy`로 정리하세요

## 🐛 문제 해결

### 일반적인 오류

**AWS CLI 미설정**
```bash
aws configure
```

**Docker 권한 오류**
```bash
sudo usermod -aG docker $USER
# 로그아웃 후 재로그인
```

**ECR 로그인 실패**
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

**배포 실패시 로그 확인**
```bash
aws logs tail /ecs/liveinsight --follow
```

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. AWS CLI 설정 상태
2. Docker 실행 상태  
3. 네트워크 연결
4. AWS 권한 설정
5. 리소스 할당량