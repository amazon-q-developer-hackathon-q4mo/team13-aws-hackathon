#!/usr/bin/env python3
"""
간단한 API 테스트 (requests 라이브러리 없이)
urllib만 사용하여 배포된 API를 테스트합니다.
"""

import urllib.request
import urllib.parse
import json
import time

# 배포된 API 기본 URL
BASE_URL = "https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev"

def make_request(url, method="GET", data=None, headers=None):
    """HTTP 요청을 보내고 응답을 반환"""
    if headers is None:
        headers = {}
    
    try:
        if data:
            data = json.dumps(data).encode('utf-8')
            headers['Content-Type'] = 'application/json'
        
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        
        with urllib.request.urlopen(req) as response:
            response_data = response.read().decode('utf-8')
            return response.status, response_data
            
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode('utf-8')
    except Exception as e:
        return None, str(e)

def test_health():
    """헬스체크 테스트"""
    print("🔍 헬스체크 테스트...")
    status, data = make_request(f"{BASE_URL}/health")
    
    if status == 200:
        print(f"✅ 성공: {data}")
        return True
    else:
        print(f"❌ 실패 ({status}): {data}")
        return False

def test_event_collection():
    """이벤트 수집 테스트"""
    print("\n🔍 이벤트 수집 테스트...")
    
    headers = {"X-API-Key": "dev-api-key-12345"}
    
    test_event = {
        "event_type": "page_view",
        "session_id": f"test-session-{int(time.time())}",
        "page_url": "https://example.com/test-page"
    }
    
    status, data = make_request(
        f"{BASE_URL}/api/events",
        method="POST",
        data=test_event,
        headers=headers
    )
    
    if status == 200:
        print(f"✅ 성공: {data}")
        return True
    else:
        print(f"❌ 실패 ({status}): {data}")
        return False

def test_realtime_stats():
    """실시간 통계 테스트"""
    print("\n🔍 실시간 통계 테스트...")
    
    headers = {"X-API-Key": "dev-api-key-12345"}
    
    status, data = make_request(
        f"{BASE_URL}/api/realtime",
        headers=headers
    )
    
    if status == 200:
        print(f"✅ 성공: {data}")
        return True
    else:
        print(f"❌ 실패 ({status}): {data}")
        return False

def main():
    """간단한 API 테스트 실행"""
    print("🚀 LiveInsight API 간단 테스트")
    print(f"📍 Base URL: {BASE_URL}")
    print("=" * 40)
    
    tests = [
        test_health,
        test_event_collection,
        test_realtime_stats
    ]
    
    success_count = 0
    for test in tests:
        if test():
            success_count += 1
        time.sleep(1)
    
    print(f"\n🎯 결과: {success_count}/{len(tests)} 성공")

if __name__ == "__main__":
    main()