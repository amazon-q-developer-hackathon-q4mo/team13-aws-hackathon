# Team13 : LiveInsight

Amazon Q Developer Hackathon으로 구현하고자 하는 아이디어를 설명합니다.

## 프로젝트 구조

```
team13-aws-hackathon/
├── src/                    # Django 애플리케이션 코드
│   ├── analytics/          # 데이터 분석 API
│   ├── dashboard/          # 대시보드 웹앱
│   ├── liveinsight/        # Django 프로젝트 설정
│   ├── static/             # 정적 파일 (JS SDK 포함)
│   └── manage.py           # Django 관리 스크립트
├── infrastructure/         # AWS 인프라 코드 (Terraform)
│   ├── main.tf             # 기본 DynamoDB 인프라
│   ├── web-app/            # ECS Fargate 웹앱 인프라
│   ├── dns/                # Route 53 DNS 설정
│   ├── cdn/                # CloudFront CDN 설정
│   ├── security/           # WAF, GuardDuty 보안 설정
│   ├── backup/             # 백업 시스템
│   ├── disaster-recovery/  # 재해복구 시스템
│   ├── monitoring-advanced/# 고급 모니터링
│   └── operations/         # 운영 자동화
├── scripts/                # 배포 및 유틸리티 스크립트
│   ├── deploy.sh           # 전체 배포 스크립트
│   ├── deploy-phase*.sh    # 단계별 배포 스크립트
│   ├── test-phase*.sh      # 단계별 테스트 스크립트
│   └── cleanup.sh          # 리소스 정리 스크립트
├── config/                 # 환경별 설정 파일
├── docs/                   # 프로젝트 문서
│   ├── dev-a/              # 개발 문서 (Phase별 계획/보고서)
│   ├── 배포가이드.md        # 배포 가이드
│   └── 테스트가이드.md      # 테스트 가이드
└── Dockerfile              # 컨테이너 이미지 정의
```

### 개발 단계별 완료 현황
- ✅ **Phase 1-5**: 서버리스 데이터 수집 인프라
- ✅ **Phase 6**: Django 웹 애플리케이션 및 ECS 배포
- ✅ **Phase 7**: 통합 테스트, 성능 최적화, 고급 모니터링
- ✅ **Phase 8**: 프로덕션 보안 (DNS, SSL, CDN, WAF)
- ✅ **Phase 9**: 백업 및 재해복구 시스템

**프로젝트 완성도**: 100% ✅

## 빠른 시작

### 로컬 개발 환경
```bash
# Django 개발 서버 시작 (네이티브)
./scripts/dev.sh native

# Docker로 개발 환경 시작
./scripts/dev.sh docker

# 로컬 테스트 실행
./scripts/test.sh local
```

### AWS 배포
```bash
# 전체 배포 (모든 Phase)
./scripts/deploy.sh

# 단계별 배포
./scripts/deploy-phase6.sh   # 웹 애플리케이션
./scripts/deploy-phase7.sh   # 최적화 및 모니터링
./scripts/deploy-phase8.sh   # 프로덕션 보안
./scripts/deploy-phase9.sh   # 백업 및 재해복구

# 배포 검증
./scripts/test.sh deployment

# 리소스 정리
./scripts/cleanup.sh
```

## 어플리케이션 개요

**LiveInsight**는 실시간 웹 분석 플랫폼으로, 웹사이트 방문자의 행동을 실시간으로 추적하고 분석하여 비즈니스 인사이트를 제공합니다.

### 핵심 기능
- **실시간 이벤트 수집**: JavaScript SDK를 통한 웹사이트 이벤트 추적
- **서버리스 데이터 처리**: AWS Lambda와 DynamoDB를 활용한 확장 가능한 데이터 처리
- **실시간 대시보드**: 방문자 현황, 페이지뷰, 이벤트 통계를 실시간으로 시각화
- **고급 분석**: 사용자 세그멘테이션, 퍼널 분석, 코호트 분석

## 주요 기능

### 1. 실시간 데이터 수집
- 페이지뷰, 클릭, 스크롤 등 사용자 행동 추적
- 사용자 세션 및 디바이스 정보 수집
- 커스텀 이벤트 정의 및 추적

### 2. 실시간 대시보드
- 현재 접속자 수 실시간 표시
- 페이지별 방문 통계
- 트래픽 소스 분석
- 디바이스 및 브라우저 분석

### 3. 고급 분석 기능
- 사용자 여정 분석
- 전환율 최적화 인사이트
- A/B 테스트 결과 분석
- 리텐션 분석

## 시스템 아키텍처

### 서버리스 아키텍처 (Phase 1-5)
- **API Gateway + Lambda**: 이벤트 수집 API
- **DynamoDB**: 실시간 데이터 저장
- **CloudWatch**: 모니터링 및 알람

### 웹 애플리케이션 (Phase 6-7)
- **ECS Fargate**: Django 웹 애플리케이션
- **Application Load Balancer**: 로드 밸런싱
- **Auto Scaling**: 자동 확장

### 프로덕션 보안 (Phase 8-9)
- **Route 53 + CloudFront**: 글로벌 CDN
- **WAF + GuardDuty**: 보안 보호
- **백업 + 재해복구**: 99.99% 가용성

## 리소스 배포하기

### 전체 배포 (권장)
```bash
# 전체 시스템 배포
./scripts/deploy.sh

# 배포 검증
./scripts/test.sh deployment
```

### 단계별 배포
```bash
# Phase 1-5: 서버리스 인프라
cd infrastructure && terraform apply

# Phase 6: 웹 애플리케이션
./scripts/deploy-phase6.sh

# Phase 7: 통합 테스트 및 최적화
./scripts/deploy-phase7.sh

# Phase 8: 프로덕션 보안
./scripts/deploy-phase8.sh

# Phase 9: 백업 및 재해복구
./scripts/deploy-phase9.sh
```

### 리소스 삭제
```bash
# 전체 리소스 삭제
./scripts/cleanup.sh

# 또는 Terraform으로 삭제
cd infrastructure && terraform destroy
```

### 월간 운영 비용
- **Phase 1-5**: $28.50 (서버리스 인프라)
- **Phase 6**: $42.00 (웹 애플리케이션)
- **Phase 7**: $18.33 (최적화)
- **Phase 8**: $25.50 (보안)
- **Phase 9**: $26.00 (백업/재해복구)
- **총 비용**: **$140.33/월**

## 프로젝트 기대 효과 및 예상 사용 사례

### 기대 효과
1. **실시간 비즈니스 인사이트**: 웹사이트 성과를 실시간으로 모니터링
2. **데이터 기반 의사결정**: 사용자 행동 데이터를 통한 전략 수립
3. **전환율 최적화**: A/B 테스트와 사용자 여정 분석을 통한 개선
4. **비용 효율적 운영**: 서버리스 아키텍처로 트래픽에 따른 자동 확장

### 예상 사용 사례

#### 1. E-commerce 웹사이트
- 상품 페이지 조회 패턴 분석
- 장바구니 이탈률 분석
- 구매 전환 퍼널 최적화

#### 2. 미디어 및 콘텐츠 사이트
- 콘텐츠 인기도 실시간 추적
- 사용자 참여도 분석
- 광고 효과 측정

#### 3. SaaS 애플리케이션
- 사용자 온보딩 프로세스 분석
- 기능별 사용률 추적
- 사용자 리텐션 분석

#### 4. 마케팅 캠페인
- 캠페인 트래픽 실시간 모니터링
- 랜딩 페이지 성과 분석
- ROI 측정 및 최적화

### 확장 가능성
- **AI/ML 통합**: 예측 분석 및 개인화 추천
- **다중 플랫폼**: 모바일 앱, IoT 디바이스 지원
- **글로벌 확장**: 다중 리전 배포
- **엔터프라이즈 기능**: GDPR 컴플라이언스, SSO 통합
