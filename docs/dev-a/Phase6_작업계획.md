# Phase 6: Django 웹 애플리케이션 AWS 인프라 구성

## 작업 개요
개발자 B가 구현한 Django 웹 애플리케이션을 AWS 클라우드에 배포하기 위한 인프라 구성 작업

## 현재 상황 분석
- Django REST API 서버 구현 완료
- 실시간 대시보드 웹 애플리케이션 구현 완료
- JavaScript 이벤트 추적 라이브러리 구현 완료
- 기존 개발자 A의 DynamoDB 인프라와 연동 필요

## Phase 6 상세 작업 계획 (3시간)

### 6.1 Django 애플리케이션 컨테이너화 (45분)
**Docker 설정**
- Dockerfile 작성 (Python 3.11, Django 환경)
- requirements.txt 최적화
- 정적 파일 수집 설정
- 환경변수 설정 (.env 파일 관리)

**컨테이너 최적화**
- 멀티스테이지 빌드 구성
- 이미지 크기 최적화
- 보안 설정 (non-root 사용자)
- 헬스체크 엔드포인트 추가

### 6.2 ECS Fargate 인프라 구성 (60분)
**ECS 클러스터 설정**
- ECS 클러스터 생성 (Fargate)
- 태스크 정의 작성
- 서비스 정의 및 오토스케일링 설정
- 로드밸런서 연동 (ALB)

**네트워킹 구성**
- VPC 및 서브넷 설정
- 보안 그룹 구성
- 인터넷 게이트웨이 연결
- NAT 게이트웨이 설정 (프라이빗 서브넷용)

### 6.3 ECR 및 CI/CD 파이프라인 (45분)
**ECR 리포지토리 설정**
- ECR 프라이빗 리포지토리 생성
- 이미지 푸시 스크립트 작성
- 이미지 태깅 전략 수립
- 라이프사이클 정책 설정

**배포 자동화**
- 빌드 및 배포 스크립트 작성
- 환경별 설정 관리
- 롤백 전략 수립
- 배포 검증 스크립트

### 6.4 기본 모니터링 설정 (30분)
**기본 CloudWatch 설정**
- 애플리케이션 로그 수집
- 기본 메트릭 수집 (CPU, 메모리)
- 기본 알람 설정 (서비스 다운)
- 로그 그룹 생성

**헬스체크 설정**
- ECS 헬스체크 엔드포인트
- ALB 헬스체크 구성
- 기본 로그 보존 정책
- 에러 로그 기본 수집

### 6.5 기본 보안 설정 (20분)
**IAM 역할 및 정책**
- ECS 태스크 실행 역할
- DynamoDB 접근 권한
- CloudWatch 로그 권한
- 최소 권한 원칙 적용

**기본 환경변수 설정**
- 필수 환경변수 설정
- 기본 보안 그룹 구성
- 프라이빗 서브넷 설정
- 기본 네트워크 보안

## 주요 산출물

### 인프라 코드
- `infrastructure/web-app/main.tf` - Terraform 인프라 정의
- `infrastructure/web-app/variables.tf` - 변수 정의
- `infrastructure/web-app/outputs.tf` - 출력 값 정의

### 컨테이너 설정
- `Dockerfile` - Django 애플리케이션 컨테이너
- `docker-compose.yml` - 로컬 개발 환경
- `.dockerignore` - 빌드 최적화

### 배포 스크립트
- `scripts/build.sh` - 이미지 빌드 스크립트
- `scripts/deploy.sh` - 배포 자동화 스크립트
- `scripts/rollback.sh` - 롤백 스크립트

### 설정 파일
- `config/production.env` - 프로덕션 환경변수
- `config/staging.env` - 스테이징 환경변수
- `nginx.conf` - 리버스 프록시 설정 (선택사항)

## 기술 스택
- **컨테이너**: Docker, ECR
- **컴퓨팅**: ECS Fargate
- **네트워킹**: VPC, ALB, Route 53
- **모니터링**: CloudWatch, X-Ray
- **보안**: IAM, Parameter Store
- **인프라**: Terraform

## 예상 비용 (월간)
- ECS Fargate (1 태스크): ~$15
- ALB: ~$20
- ECR 스토리지: ~$2
- 기본 CloudWatch: ~$5
- **Phase 6 비용**: ~$42/월
- **누적 총 비용**: ~$42/월

## 성공 기준 체크리스트
- [ ] Django 애플리케이션이 ECS Fargate에서 정상 실행
- [ ] ALB를 통한 HTTP 접근 가능
- [ ] DynamoDB와 정상 연동 확인
- [ ] 실시간 대시보드 정상 동작
- [ ] 기본 모니터링 및 헬스체크 동작
- [ ] 자동 배포 파이프라인 구축

## 다음 단계
- Phase 7: 통합 테스트 및 성능 최적화
- Phase 8: 도메인 연결 및 SSL 인증서 설정
- Phase 9: 백업 및 재해복구 계획 수립