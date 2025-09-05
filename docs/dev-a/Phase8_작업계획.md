# Phase 8: 도메인 연결 및 SSL 인증서 설정

## 작업 개요
프로덕션 환경을 위한 커스텀 도메인 연결, SSL/TLS 인증서 설정, 보안 강화 및 CDN 구성

## 현재 상황 분석
- 통합 테스트 및 성능 최적화 (Phase 7) 완료
- ALB를 통한 HTTP 접근 가능
- 프로덕션 배포를 위한 도메인 및 보안 설정 필요

## Phase 8 상세 작업 계획 (2.5시간)

### 8.1 도메인 및 DNS 설정 (45분)
**Route 53 설정**
- 호스팅 존 생성 (liveinsight.com 예시)
- A 레코드 생성 (ALB 연결)
- CNAME 레코드 설정 (www 서브도메인)
- 헬스체크 설정

**서브도메인 구성**
- `api.liveinsight.com` - REST API 엔드포인트
- `dashboard.liveinsight.com` - 대시보드 웹앱
- `tracker.liveinsight.com` - JavaScript 라이브러리 CDN
- `admin.liveinsight.com` - 관리자 페이지

### 8.2 SSL/TLS 인증서 설정 (30분)
**AWS Certificate Manager (ACM)**
- 와일드카드 인증서 요청 (*.liveinsight.com)
- DNS 검증 방식 설정
- 인증서 자동 갱신 설정
- ALB HTTPS 리스너 구성

**보안 헤더 설정**
- HSTS (HTTP Strict Transport Security)
- CSP (Content Security Policy)
- X-Frame-Options
- X-Content-Type-Options

### 8.3 CDN 및 정적 자산 최적화 (60분)
**CloudFront 배포 설정**
- 정적 파일 CDN 구성
- JavaScript 라이브러리 글로벌 배포
- 캐시 정책 최적화
- 압축 및 최적화 설정

**S3 정적 호스팅**
- 정적 자산 S3 버킷 생성
- CloudFront 오리진 설정
- 버전 관리 및 캐시 무효화
- 접근 권한 최적화

### 8.4 통합 보안 강화 (45분)
**WAF (Web Application Firewall) 설정**
- SQL 인젝션 방어 규칙
- XSS 공격 방어 규칙
- DDoS 방어 설정
- IP 화이트리스트/블랙리스트

**보안 그룹 고도화** (Phase 6에서 이관)
- 최소 권한 원칙 적용
- 불필요한 포트 차단 (80, 443만 허용)
- 소스 IP 제한 (내부 네트워크만)
- 로그 감사 설정 및 모니터링

**고급 보안 설정**
- VPC Flow Logs 활성화
- GuardDuty 연돐 (선택사항)
- Config Rules 설정
- CloudTrail 감사 로그

### 8.5 통합 환경 관리 (30분)
**다중 환경 구성** (Phase 6에서 이관)
- 개발(dev), 스테이징(staging), 프로덕션(prod) 환경 분리
- 환경별 도메인 설정 (dev.liveinsight.com, staging.liveinsight.com)
- 환경별 SSL 인증서 및 자동 갱신
- 환경별 모니터링 및 알람 설정

**고급 환경변수 관리**
- AWS Systems Manager Parameter Store 통합
- 민감 정보 암호화 (KMS)
- 환경별 설정 검증 로직
- 설정 변경 추적 및 감사

## 주요 산출물

### 인프라 코드
- `infrastructure/dns/main.tf` - Route 53 설정
- `infrastructure/cdn/main.tf` - CloudFront 설정
- `infrastructure/security/main.tf` - WAF 및 보안 설정
- `infrastructure/ssl/main.tf` - ACM 인증서 설정

### 설정 파일
- `config/cloudfront.json` - CDN 설정
- `config/waf-rules.json` - WAF 규칙 정의
- `config/security-headers.conf` - 보안 헤더 설정
- `nginx/ssl.conf` - SSL 설정 (필요시)

### 스크립트
- `scripts/deploy-cdn.sh` - CDN 배포 스크립트
- `scripts/ssl-setup.sh` - SSL 설정 스크립트
- `scripts/domain-setup.sh` - 도메인 설정 스크립트

### 문서화
- `docs/도메인설정가이드.md` - 도메인 설정 가이드
- `docs/보안설정가이드.md` - 보안 설정 가이드
- `docs/SSL인증서관리.md` - SSL 인증서 관리 가이드

## 기술 스택
- **DNS**: Route 53
- **SSL/TLS**: AWS Certificate Manager
- **CDN**: CloudFront
- **보안**: WAF, Security Groups
- **스토리지**: S3

## 예상 비용 (월간)
- Route 53 호스팅 존: $0.50
- ACM 인증서: 무료
- CloudFront: ~$10 (1TB 전송 기준)
- WAF: ~$5
- **Phase 8 비용**: ~$15.50/월
- **누적 총 비용**: ~$57.50/월 (Phase 6: $42 + Phase 8: $15.50)

## 보안 체크리스트
- [ ] HTTPS 강제 리다이렉트 설정
- [ ] 보안 헤더 모든 응답에 포함
- [ ] WAF 규칙 테스트 완료
- [ ] SSL Labs A+ 등급 달성
- [ ] 취약점 스캔 통과
- [ ] 접근 로그 모니터링 설정

## 성공 기준 체크리스트
- [ ] HTTPS 도메인으로 접근 가능
- [ ] SSL Labs A+ 등급 달성
- [ ] CDN을 통한 정적 자산 배포 완료
- [ ] WAF 보안 규칙 정상 동작
- [ ] 모든 환경별 설정 완료
- [ ] 보안 감사 통과
- [ ] 고급 보안 설정 적용 완료