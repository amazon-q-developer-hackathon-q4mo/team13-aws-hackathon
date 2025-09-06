"""
E-commerce 웹사이트 운영자 시나리오 테스트 케이스
시나리오 1: 김대리의 하루 업무 흐름 테스트
"""

import pytest
import requests
import json
import time
from datetime import datetime, timedelta
from unittest.mock import Mock, patch


class TestEcommerceScenario:
    """E-commerce 웹사이트 운영자 시나리오 테스트"""
    
    def setup_method(self):
        """테스트 환경 설정"""
        self.base_url = "http://localhost:8000/api"
        self.events_api = "https://your-api-gateway-url/events"
        self.test_user_id = "user_test_kim"
        self.test_session_id = f"sess_{int(time.time())}_kim"
        
    def test_morning_dashboard_check(self):
        """테스트 케이스 1: 아침 업무 시작 - 대시보드 현황 확인"""
        
        # Given: 김대리가 아침에 출근하여 대시보드에 접속
        print("🌅 테스트: 아침 업무 시작 (09:00)")
        
        # When: 실시간 지표 확인
        response = requests.get(f"{self.base_url}/statistics/summary/")
        
        # Then: 현재 활성 사용자 수와 주요 지표 확인 가능
        assert response.status_code == 200
        data = response.json()
        
        assert "total_sessions" in data
        assert "total_events" in data
        assert "avg_session_time" in data
        assert "conversion_rate" in data
        
        print(f"✅ 현재 활성 사용자: {data['total_sessions']}")
        print(f"✅ 총 이벤트 수: {data['total_events']}")
        print(f"✅ 평균 세션 시간: {data['avg_session_time']}")
        print(f"✅ 전환율: {data['conversion_rate']}")
        
    def test_realtime_traffic_monitoring(self):
        """테스트 케이스 2: 실시간 모니터링 - 트래픽 급증 감지"""
        
        print("📈 테스트: 실시간 트래픽 모니터링 (10:30)")
        
        # Given: 특정 상품 페이지에 트래픽 집중 상황 시뮬레이션
        product_page = "/products/special-item"
        
        # When: 시간대별 통계 조회
        response = requests.get(f"{self.base_url}/statistics/hourly/")
        
        # Then: 트래픽 증가 확인 가능
        assert response.status_code == 200
        hourly_data = response.json()
        
        assert isinstance(hourly_data, list)
        assert len(hourly_data) > 0
        
        # 최근 시간대 데이터 확인
        latest_hour = hourly_data[-1]
        assert "hour" in latest_hour
        assert "count" in latest_hour
        
        print(f"✅ 최근 시간대 ({latest_hour['hour']}) 이벤트 수: {latest_hour['count']}")
        
        # When: 페이지별 통계에서 해당 상품 페이지 확인
        response = requests.get(f"{self.base_url}/statistics/pages/")
        assert response.status_code == 200
        
        page_stats = response.json()
        if page_stats:
            top_page = page_stats[0]
            print(f"✅ 최고 조회 페이지: {top_page['page']} ({top_page['views']}회)")
        
    def test_lunch_traffic_analysis(self):
        """테스트 케이스 3: 점심시간 트래픽 분석 - 유입경로 확인"""
        
        print("🍽️ 테스트: 점심시간 유입경로 분석 (12:00)")
        
        # When: 유입경로별 통계 조회
        response = requests.get(f"{self.base_url}/statistics/referrers/")
        
        # Then: 유입경로 분포 확인 가능
        assert response.status_code == 200
        referrer_data = response.json()
        
        assert "labels" in referrer_data
        assert "data" in referrer_data
        assert len(referrer_data["labels"]) == len(referrer_data["data"])
        
        # 주요 유입경로 확인
        referrer_stats = dict(zip(referrer_data["labels"], referrer_data["data"]))
        
        print("✅ 유입경로별 통계:")
        for source, count in referrer_stats.items():
            percentage = (count / sum(referrer_data["data"]) * 100) if sum(referrer_data["data"]) > 0 else 0
            print(f"   {source}: {count}명 ({percentage:.1f}%)")
            
    def test_afternoon_performance_analysis(self):
        """테스트 케이스 4: 오후 성과 분석 - 이탈률 분석"""
        
        print("📊 테스트: 오후 성과 분석 (15:00)")
        
        # Given: 장바구니 페이지 이탈 상황 시뮬레이션
        cart_page = "/cart"
        
        # When: 특정 페이지 상세 분석
        response = requests.get(f"{self.base_url}/dashboard/page-details/", 
                              params={"page": cart_page})
        
        # Then: 페이지별 상세 통계 확인
        if response.status_code == 200:
            page_data = response.json()
            
            assert "page_url" in page_data
            assert "total_views" in page_data
            assert "recent_events" in page_data
            assert "hourly_distribution" in page_data
            
            print(f"✅ {cart_page} 총 조회수: {page_data['total_views']}")
            print(f"✅ 최근 이벤트 수: {len(page_data['recent_events'])}")
        else:
            print("⚠️ 해당 페이지 데이터 없음 (정상적인 경우)")
            
    def test_active_sessions_monitoring(self):
        """테스트 케이스 5: 활성 세션 실시간 모니터링"""
        
        print("👥 테스트: 활성 세션 모니터링")
        
        # When: 현재 활성 세션 조회
        response = requests.get(f"{self.base_url}/sessions/active/")
        
        # Then: 활성 세션 목록 확인
        assert response.status_code == 200
        active_sessions = response.json()
        
        assert isinstance(active_sessions, list)
        
        print(f"✅ 현재 활성 세션 수: {len(active_sessions)}")
        
        # 각 세션 정보 검증
        for session in active_sessions[:3]:  # 최대 3개만 출력
            assert "session_id" in session
            assert "user_id" in session
            assert "current_page" in session
            assert "duration" in session
            
            duration_minutes = session["duration"] // 60000  # 밀리초를 분으로 변환
            print(f"   세션 {session['session_id'][:20]}... - {session['current_page']} ({duration_minutes}분)")


class TestEcommerceScenarioIntegration:
    """E-commerce 시나리오 통합 테스트"""
    
    def test_full_day_workflow(self):
        """김대리의 하루 전체 워크플로우 통합 테스트"""
        
        print("🏢 통합 테스트: 김대리의 하루 업무 흐름")
        
        base_url = "http://localhost:8000/api"
        
        # 1. 아침 대시보드 체크
        summary_response = requests.get(f"{base_url}/statistics/summary/")
        assert summary_response.status_code == 200
        print("✅ 1단계: 아침 대시보드 체크 완료")
        
        # 2. 실시간 모니터링
        hourly_response = requests.get(f"{base_url}/statistics/hourly/")
        assert hourly_response.status_code == 200
        print("✅ 2단계: 실시간 모니터링 완료")
        
        # 3. 유입경로 분석
        referrer_response = requests.get(f"{base_url}/statistics/referrers/")
        assert referrer_response.status_code == 200
        print("✅ 3단계: 유입경로 분석 완료")
        
        # 4. 페이지 성과 분석
        pages_response = requests.get(f"{base_url}/statistics/pages/")
        assert pages_response.status_code == 200
        print("✅ 4단계: 페이지 성과 분석 완료")
        
        # 5. 활성 세션 모니터링
        sessions_response = requests.get(f"{base_url}/sessions/active/")
        assert sessions_response.status_code == 200
        print("✅ 5단계: 활성 세션 모니터링 완료")
        
        print("🎉 김대리의 하루 업무 흐름 테스트 완료!")


if __name__ == "__main__":
    # 개별 테스트 실행 예시
    test_case = TestEcommerceScenario()
    test_case.setup_method()
    
    print("🧪 E-commerce 시나리오 테스트 시작\n")
    
    try:
        test_case.test_morning_dashboard_check()
        print()
        test_case.test_realtime_traffic_monitoring()
        print()
        test_case.test_lunch_traffic_analysis()
        print()
        test_case.test_afternoon_performance_analysis()
        print()
        test_case.test_active_sessions_monitoring()
        print()
        
        # 통합 테스트
        integration_test = TestEcommerceScenarioIntegration()
        integration_test.test_full_day_workflow()
        
        print("\n🎉 모든 테스트 완료!")
        
    except Exception as e:
        print(f"\n❌ 테스트 실패: {str(e)}")
        print("💡 Django 서버가 실행 중인지 확인하세요: python manage.py runserver")