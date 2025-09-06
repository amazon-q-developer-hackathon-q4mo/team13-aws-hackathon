# Team13 : 실시간 웹사이트 방문자 분석 서비스 'LiveInsight'

`LiveInsight는` 웹사이트 운영자와 마케터가 방문자의 행동을 실시간으로 이해할 수 있도록 설계된 차세대 웹 분석 플랫폼입니다.
기존 `Google Analytics`처럼 복잡한 설정이나 지연된 데이터 처리 없이, 직관적인 대시보드를 통해 “지금 이 순간” 웹사이트에서 일어나는 모든 활동을 즉시 확인할 수 있습니다.
마치 매장에서 고객의 동선을 실시간으로 관찰하듯, 방문자가 어떤 페이지를 보고 어떤 버튼을 클릭하며 어디서 이탈하는지를 초 단위로 추적하여 즉각적인 비즈니스 의사결정을 지원합니다.

<div align="center"> <img src="https://github.com/user-attachments/assets/5fb7aa8a-c9b7-48fa-a8b5-c1dc2f920cc1" width="40%"/> <img src="https://github.com/user-attachments/assets/9bbcc207-c2b6-4609-b19b-869bfc5b9bc2" width="59%"/> </div>


### 📊 제공하는 인사이트
**실시간 모니터링:** 
- 현재 활성 사용자 수 및 세션 정보
- 페이지별 실시간 조회수 및 체류 시간
- 유입 경로별 트래픽 분포 (검색, 소셜, 직접 유입 등)
- 디바이스/브라우저별 사용 현황 

**행동 분석:** 
- 사용자 여정 맵 (어떤 순서로 페이지를 방문하는가)
- 클릭 히트맵 (어떤 요소를 가장 많이 클릭하는가)
- 스크롤 깊이 분석 (콘텐츠를 얼마나 읽는가)
- 이탈 지점 분석 (어디서 사용자가 떠나는가)

**비즈니스 메트릭:**
- 전환율 및 전환 퍼널 분석
- 고객 생애 가치 (CLV) 추적
- 리텐션 및 재방문율 분석
- ROI 및 마케팅 성과 측정

## 🔥 주요 기능
<p align="center">
  <img src="https://github.com/user-attachments/assets/789ca762-6d61-43c9-8749-a339d6d238a3" width="300"/>
  <img src="https://github.com/user-attachments/assets/0d13eb74-13c8-4bfe-9011-7c09a3bfa017" width="300"/>
  <img src="https://github.com/user-attachments/assets/37bf10c0-6891-430d-a48b-41e05fbded80" width="300"/>
</p>

1. **실시간 이벤트 수집**

    **LiveInsight의** 실시간 이벤트 수집 시스템은 웹사이트 방문자의 모든 행동을 초 단위로 추적하는 혁신적인 시스템입니다. 기존 분석 도구들이 데이터 처리에 수시간에서 수일이 걸리는 반면, **LiveInsight는** `JavaScript SDK`를 통해 페이지뷰, 클릭, 스크롤, 폼 제출 등 다양한 이벤트를 즉시 추적하고 1초 이내에 대시보드에 반영합니다.
    또한 비즈니스 특성에 맞는 **커스텀 이벤트(구매, 회원가입, 다운로드 등)**를 자유롭게 정의하여 추적할 수 있으며, 사용자 세션 및 디바이스 정보까지 자동 수집해 각 비즈니스에 최적화된 분석이 가능합니다.

2. **서버리스 데이터 처리**

    **LiveInsight의** 데이터 처리 엔진은 `AWS Lambda`와 `DynamoDB`를 기반으로 구축되어 초당 수천 건의 이벤트를 안정적으로 처리합니다.
    트래픽 급증 시에도 자동 스케일링을 통해 성능 저하 없이 확장 가능하며, 데이터 무결성 보장 및 중복 제거 기능으로 신뢰성 높은 데이터를 제공합니다.

3. **실시간 대시보드**

    **LiveInsight의** 대시보드는 복잡한 데이터를 직관적이고 아름다운 시각적 요소로 변환하여 제공합니다.
    현재 접속자 수, 페이지별 실시간 조회수, 유입 경로별 트래픽 분포, 디바이스/브라우저별 사용 현황 등 핵심 지표를 한눈에 파악할 수 있습니다.
    또한 알람 및 임계값 설정을 통해 중요한 이벤트를 즉시 감지할 수 있으며, 모바일 반응형 디자인으로 언제 어디서나 손쉽게 모니터링이 가능합니다.


## 시스템 아키텍처


```mermaid
graph TB
    subgraph "사용자 레이어"
        U[웹사이트 방문자]
        D[대시보드 사용자]
    end

    subgraph "웹 애플리케이션"
        ALB[Application Load Balancer]
        ECS[ECS Fargate<br/>Django App]
    end

    subgraph "서버리스 백엔드"
        APIG[API Gateway]
        L1[Lambda<br/>이벤트 수집]
        L2[Lambda<br/>데이터 처리]
    end

    subgraph "데이터 저장소"
        DDB[DynamoDB<br/>실시간 데이터]
        S3[S3<br/>백업 & 로그]
    end

    U -->|JavaScript SDK| APIG
    D -->|HTTPS| ALB
    ALB --> ECS
    APIG --> L1
    L1 --> L2
    L2 --> DDB
    ECS --> DDB
    DDB --> S3
    
    style U fill:#e1f5fe
    style D fill:#e1f5fe
    style DDB fill:#fff3e0
    style ECS fill:#e8f5e8
    style L1 fill:#fff9c4
    style L2 fill:#fff9c4
```
<div align="center">

| 서버리스 아키텍처 | 웹 애플리케이션 |
|-------------------------------|----------------------------|
| - **API Gateway + Lambda**: 이벤트 수집 API<br/>- **DynamoDB**: 실시간 데이터 저장<br/>- **CloudWatch**: 모니터링 및 알람 | - **ECS Fargate**: Django 웹 애플리케이션<br/>- **Application Load Balancer**: 로드 밸런싱<br/>- **Auto Scaling**: 자동 확장 |

</div>



## 🚀 배포하기

자세한 배포 방법은 [배포가이드.md](./배포가이드.md)를 참고하세요.

### 빠른 시작
```bash
# 1. 인프라 배포
cd infrastructure
terraform init
terraform apply

# 2. 애플리케이션 배포
cd ..
./scripts/build.sh

# 3. 배포 검증
./scripts/test.sh deployment
```

## 🧪 테스트하기

자세한 테스트 방법은 [테스트가이드.md](./테스트가이드.md)를 참고하세요.

### 빠른 테스트
```bash
# 전체 테스트 실행
./scripts/run-tests.sh

# 개별 테스트
./scripts/test.sh deployment
./scripts/run-tests.sh performance
```
## 프로젝트 기대 효과 및 예상 사용 사례

### 기대 효과
1. **실시간 비즈니스 인사이트**: 웹사이트 성과를 실시간으로 모니터링
2. **데이터 기반 의사결정**: 사용자 행동 데이터를 통한 전략 수립
3. **전환율 최적화**: A/B 테스트와 사용자 여정 분석을 통한 개선
4. **비용 효율적 운영**: 서버리스 아키텍처로 트래픽에 따른 자동 확장

### 예상 사용 사례
1. **E-commerce 웹사이트**
    - 상품 페이지 조회 패턴 분석
    - 장바구니 이탈률 분석
    - 구매 전환 퍼널 최적화
2. **미디어 및 콘텐츠 사이트**
    - 콘텐츠 인기도 실시간 추적
    - 사용자 참여도 분석
    - 광고 효과 측정

3. **SaaS 애플리케이션**
    - 사용자 온보딩 프로세스 분석
    - 기능별 사용률 추적
    - 사용자 리텐션 분석

4. 마케팅 캠페인
    - 캠페인 트래픽 실시간 모니터링
    - 랜딩 페이지 성과 분석
    - ROI 측정 및 최적화

### 확장 가능성
- **AI/ML 통합**: 예측 분석 및 개인화 추천
- **다중 플랫폼**: 모바일 앱, IoT 디바이스 지원
- **글로벌 확장**: 다중 리전 배포
- **엔터프라이즈 기능**: GDPR 컴플라이언스, SSO 통합
