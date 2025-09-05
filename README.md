# Team13 : LiveInsight

Amazon Q Developer Hackathon으로 구현하고자 하는 아이디어를 설명합니다.

## 프로젝트 구조

```
team13-aws-hackathon/
├── src/                    # Django 애플리케이션 코드
│   ├── analytics/          # 데이터 분석 API
│   ├── dashboard/          # 대시보드 웹앱
│   ├── liveinsight/        # Django 프로젝트 설정
│   ├── static/             # 정적 파일
│   └── manage.py           # Django 관리 스크립트
├── infrastructure/         # AWS 인프라 코드
│   ├── web-app/            # ECS Fargate 인프라
│   └── main.tf             # DynamoDB 인프라
├── scripts/                # 배포 및 유틸리티 스크립트
├── config/                 # 환경별 설정 파일
├── docs/                   # 문서
└── Dockerfile              # 컴테이너 이미지 정의
```

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
# 전체 배포
./scripts/deploy.sh

# 배포 검증
./scripts/test.sh deployment

# 롤백
./scripts/rollback.sh
```

## 어플리케이션 개요

구현하고자 하는 어플리케이션의 목적 및 기능과 같은 어플리케이션에 대한 설명을 입력합니다.

## 주요 기능

어플리케이션의 주요 기능 들을 설명합니다. 가능하다면 각 화면의 캡처를 기반으로 설명 자료를 작성합니다.

## 동영상 데모

Amazon Q Developer로 구현한 어플리케이션의 데모 영상을 입력합니다.
**Git의 Readme에는 GIF 형식으로 업로드하며, 원본 동영상은 발표 Presentation에 제출합니다.**

## 리소스 배포하기

해당 코드를 AWS 상에 배포하기 위한 방법을 설명합니다. 인프라를 배포했을 경우 출력되는 AWS 아키텍처도 함께 포함하며, 리소스를 삭제하는 방안도 함께 작성합니다.

## 프로젝트 기대 효과 및 예상 사용 사례

해당 프로젝트의 기대 효과와 예상되는 사용 사례를 작성합니다.
