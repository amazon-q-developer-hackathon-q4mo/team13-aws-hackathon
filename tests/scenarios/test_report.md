
# E-commerce 시나리오 테스트 보고서

**테스트 실행 시간**: 2025-09-06 12:11:48

## 테스트 시나리오
김대리(E-commerce 웹사이트 운영자)의 하루 업무 흐름을 시뮬레이션

### 테스트 케이스
1. **아침 업무 시작 (09:00)**: 대시보드 현황 확인
2. **실시간 모니터링 (10:30)**: 트래픽 급증 감지
3. **점심시간 분석 (12:00)**: 유입경로 확인
4. **오후 성과 분석 (15:00)**: 이탈률 분석
5. **활성 세션 모니터링**: 실시간 사용자 현황

### API 엔드포인트 테스트
- GET /api/statistics/summary/ - 요약 통계
- GET /api/statistics/hourly/ - 시간대별 통계
- GET /api/statistics/pages/ - 페이지별 통계
- GET /api/statistics/referrers/ - 유입경로 통계
- GET /api/sessions/active/ - 활성 세션

### 검증 항목
- API 응답 상태 코드 (200 OK)
- 응답 데이터 구조 검증
- 필수 필드 존재 확인
- 데이터 타입 검증
- 비즈니스 로직 정합성

## 실행 방법
```bash
cd tests/scenarios
python test_runner.py
```

## 전제 조건
- Django 서버 실행 (localhost:8000)
- DynamoDB 테이블 생성 완료
- 테스트 데이터 존재
