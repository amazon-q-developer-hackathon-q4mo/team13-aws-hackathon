"""
pytest 설정 파일
E-commerce 시나리오 테스트를 위한 공통 설정
"""

import pytest
import requests
import time
from datetime import datetime


@pytest.fixture(scope="session")
def api_base_url():
    """API 기본 URL"""
    return "http://localhost:8000/api"


@pytest.fixture(scope="session")
def test_user_data():
    """테스트용 사용자 데이터"""
    return {
        "user_id": "user_test_kim",
        "session_id": f"sess_{int(time.time())}_kim",
        "test_pages": [
            "/home",
            "/products/special-item",
            "/cart",
            "/checkout",
            "/products/category/electronics"
        ]
    }


@pytest.fixture(scope="function")
def mock_events_data():
    """테스트용 이벤트 데이터"""
    current_time = int(time.time() * 1000)
    
    return [
        {
            "user_id": "user_test_001",
            "session_id": "sess_test_001",
            "event_type": "page_view",
            "page_url": "/home",
            "referrer": "https://google.com",
            "timestamp": current_time - 3600000  # 1시간 전
        },
        {
            "user_id": "user_test_002", 
            "session_id": "sess_test_002",
            "event_type": "page_view",
            "page_url": "/products/special-item",
            "referrer": "https://facebook.com",
            "timestamp": current_time - 1800000  # 30분 전
        },
        {
            "user_id": "user_test_003",
            "session_id": "sess_test_003", 
            "event_type": "click",
            "page_url": "/cart",
            "referrer": "",
            "timestamp": current_time - 900000   # 15분 전
        }
    ]


@pytest.fixture(scope="session", autouse=True)
def check_server_running(api_base_url):
    """테스트 시작 전 서버 상태 확인"""
    try:
        response = requests.get(f"{api_base_url}/statistics/summary/", timeout=5)
        if response.status_code != 200:
            pytest.skip("Django 서버가 실행되지 않았습니다. 'python manage.py runserver'로 서버를 시작하세요.")
    except requests.exceptions.RequestException:
        pytest.skip("Django 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하세요.")


@pytest.fixture(scope="function")
def api_client(api_base_url):
    """API 클라이언트 헬퍼"""
    class APIClient:
        def __init__(self, base_url):
            self.base_url = base_url
            
        def get(self, endpoint, params=None):
            """GET 요청"""
            url = f"{self.base_url}{endpoint}"
            return requests.get(url, params=params)
            
        def post(self, endpoint, data=None):
            """POST 요청"""
            url = f"{self.base_url}{endpoint}"
            return requests.post(url, json=data)
            
        def get_summary_stats(self):
            """요약 통계 조회"""
            return self.get("/statistics/summary/")
            
        def get_hourly_stats(self, hours=24):
            """시간대별 통계 조회"""
            return self.get("/statistics/hourly/", params={"hours": hours})
            
        def get_page_stats(self):
            """페이지별 통계 조회"""
            return self.get("/statistics/pages/")
            
        def get_referrer_stats(self):
            """유입경로 통계 조회"""
            return self.get("/statistics/referrers/")
            
        def get_active_sessions(self):
            """활성 세션 조회"""
            return self.get("/sessions/active/")
            
        def get_session_events(self, session_id):
            """세션별 이벤트 조회"""
            return self.get(f"/sessions/{session_id}/events/")
    
    return APIClient(api_base_url)


@pytest.fixture(scope="function")
def performance_monitor():
    """성능 모니터링 헬퍼"""
    class PerformanceMonitor:
        def __init__(self):
            self.start_time = None
            self.end_time = None
            
        def start(self):
            """측정 시작"""
            self.start_time = time.time()
            
        def stop(self):
            """측정 종료"""
            self.end_time = time.time()
            
        def get_duration_ms(self):
            """측정 시간 반환 (밀리초)"""
            if self.start_time and self.end_time:
                return (self.end_time - self.start_time) * 1000
            return None
            
        def assert_response_time(self, max_ms=1000):
            """응답 시간 검증"""
            duration = self.get_duration_ms()
            assert duration is not None, "측정이 완료되지 않았습니다"
            assert duration < max_ms, f"응답 시간 초과: {duration:.2f}ms > {max_ms}ms"
            
    return PerformanceMonitor()


def pytest_configure(config):
    """pytest 설정"""
    config.addinivalue_line(
        "markers", "slow: 느린 테스트 마킹"
    )
    config.addinivalue_line(
        "markers", "integration: 통합 테스트 마킹"
    )
    config.addinivalue_line(
        "markers", "scenario: 시나리오 테스트 마킹"
    )


def pytest_collection_modifyitems(config, items):
    """테스트 아이템 수정"""
    for item in items:
        # 시나리오 테스트 마킹
        if "scenario" in item.nodeid:
            item.add_marker(pytest.mark.scenario)
            
        # 통합 테스트 마킹
        if "integration" in item.name.lower():
            item.add_marker(pytest.mark.integration)


@pytest.fixture(scope="session")
def test_report_data():
    """테스트 보고서 데이터"""
    return {
        "start_time": datetime.now(),
        "test_results": [],
        "performance_data": []
    }