#!/usr/bin/env python3
"""
E-commerce 시나리오 테스트 실행기
"""

import sys
import os
import subprocess
import time
import requests
from datetime import datetime

# Django 프로젝트 경로 추가
sys.path.append('/Users/kimphysicsman/workspace/aws/amazon-q-developer-hackathon/team13-aws-hackathon/src')

def check_server_status():
    """Django 서버 상태 확인"""
    try:
        response = requests.get("http://localhost:8000/api/statistics/summary/", timeout=5)
        return response.status_code == 200
    except:
        return False

def run_scenario_test():
    """시나리오 테스트 실행"""
    
    print("🚀 LiveInsight E-commerce 시나리오 테스트 시작")
    print("=" * 60)
    
    # 서버 상태 확인
    if not check_server_status():
        print("❌ Django 서버가 실행되지 않았습니다.")
        print("💡 다음 명령어로 서버를 시작하세요:")
        print("   cd src && python manage.py runserver")
        return False
    
    print("✅ Django 서버 연결 확인")
    print()
    
    # 테스트 실행
    try:
        from test_ecommerce_scenario import TestEcommerceScenario, TestEcommerceScenarioIntegration
        
        # 개별 테스트 실행
        test_case = TestEcommerceScenario()
        test_case.setup_method()
        
        print("📋 개별 테스트 케이스 실행")
        print("-" * 40)
        
        test_methods = [
            ("아침 대시보드 체크", test_case.test_morning_dashboard_check),
            ("실시간 트래픽 모니터링", test_case.test_realtime_traffic_monitoring),
            ("점심시간 유입경로 분석", test_case.test_lunch_traffic_analysis),
            ("오후 성과 분석", test_case.test_afternoon_performance_analysis),
            ("활성 세션 모니터링", test_case.test_active_sessions_monitoring),
        ]
        
        passed_tests = 0
        total_tests = len(test_methods)
        
        for test_name, test_method in test_methods:
            try:
                print(f"\n🧪 {test_name} 테스트 실행...")
                test_method()
                print(f"✅ {test_name} 테스트 통과")
                passed_tests += 1
            except Exception as e:
                print(f"❌ {test_name} 테스트 실패: {str(e)}")
        
        print("\n" + "=" * 60)
        print(f"📊 테스트 결과: {passed_tests}/{total_tests} 통과")
        
        # 통합 테스트 실행
        if passed_tests == total_tests:
            print("\n🔄 통합 테스트 실행...")
            integration_test = TestEcommerceScenarioIntegration()
            try:
                integration_test.test_full_day_workflow()
                print("✅ 통합 테스트 통과")
            except Exception as e:
                print(f"❌ 통합 테스트 실패: {str(e)}")
        
        return passed_tests == total_tests
        
    except ImportError as e:
        print(f"❌ 테스트 모듈 임포트 실패: {str(e)}")
        return False
    except Exception as e:
        print(f"❌ 테스트 실행 중 오류: {str(e)}")
        return False

def generate_test_report():
    """테스트 보고서 생성"""
    
    report = f"""
# E-commerce 시나리오 테스트 보고서

**테스트 실행 시간**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

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
"""
    
    with open("test_report.md", "w", encoding="utf-8") as f:
        f.write(report)
    
    print("📄 테스트 보고서 생성: test_report.md")

if __name__ == "__main__":
    success = run_scenario_test()
    generate_test_report()
    
    if success:
        print("\n🎉 모든 테스트가 성공적으로 완료되었습니다!")
        sys.exit(0)
    else:
        print("\n⚠️ 일부 테스트가 실패했습니다. 로그를 확인하세요.")
        sys.exit(1)