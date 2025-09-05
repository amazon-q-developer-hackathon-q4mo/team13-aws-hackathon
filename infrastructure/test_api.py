#!/usr/bin/env python3
import requests
import json
import time
import uuid

def test_event_collection():
    """API 엔드포인트 테스트"""
    api_url = "https://qnwoi1ardd.execute-api.us-east-1.amazonaws.com/prod/events"
    
    # 테스트 시나리오
    test_events = [
        # 1. 새 사용자 첫 방문
        {
            "user_id": "test_user_001",
            "event_type": "page_view",
            "page_url": "https://example.com/home",
            "referrer": "https://google.com",
            "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
        },
        # 2. 같은 사용자 다른 페이지 방문 (세션 유지)
        {
            "user_id": "test_user_001", 
            "event_type": "page_view",
            "page_url": "https://example.com/products",
            "referrer": "https://example.com/home"
        },
        # 3. 클릭 이벤트
        {
            "user_id": "test_user_001",
            "event_type": "click",
            "page_url": "https://example.com/products",
            "referrer": "https://example.com/home"
        },
        # 4. 다른 사용자
        {
            "user_id": "test_user_002",
            "event_type": "page_view", 
            "page_url": "https://example.com/about",
            "referrer": "https://facebook.com"
        }
    ]
    
    print("🧪 API 테스트 시작...")
    print(f"📡 API URL: {api_url}")
    print("-" * 60)
    
    session_ids = {}
    
    for i, event_data in enumerate(test_events, 1):
        print(f"\n📤 테스트 {i}: {event_data['event_type']} - {event_data['user_id']}")
        
        # 이전 세션 ID가 있으면 사용
        user_id = event_data['user_id']
        if user_id in session_ids:
            event_data['session_id'] = session_ids[user_id]
        
        try:
            response = requests.post(api_url, json=event_data, timeout=10)
            
            print(f"📥 응답 코드: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ 성공: {result['message']}")
                print(f"🆔 Event ID: {result['event_id']}")
                print(f"🔗 Session ID: {result['session_id']}")
                
                # 세션 ID 저장
                session_ids[user_id] = result['session_id']
            else:
                print(f"❌ 실패: {response.text}")
                
        except requests.exceptions.RequestException as e:
            print(f"🚨 네트워크 오류: {e}")
        except json.JSONDecodeError as e:
            print(f"🚨 JSON 파싱 오류: {e}")
        
        time.sleep(1)  # API 호출 간격
    
    print("\n" + "=" * 60)
    print("🎯 테스트 완료!")
    print(f"📊 수집된 세션: {len(session_ids)}개")
    for user_id, session_id in session_ids.items():
        print(f"   {user_id}: {session_id}")

def test_cors():
    """CORS 테스트"""
    api_url = "https://qnwoi1ardd.execute-api.us-east-1.amazonaws.com/prod/events"
    
    print("\n🔒 CORS 테스트...")
    
    try:
        response = requests.options(api_url, timeout=10)
        print(f"📥 OPTIONS 응답 코드: {response.status_code}")
        
        if response.status_code == 200:
            headers = response.headers
            print("✅ CORS 헤더:")
            for header in ['Access-Control-Allow-Origin', 'Access-Control-Allow-Methods', 'Access-Control-Allow-Headers']:
                if header in headers:
                    print(f"   {header}: {headers[header]}")
        else:
            print(f"❌ CORS 실패: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"🚨 CORS 테스트 오류: {e}")

if __name__ == "__main__":
    test_event_collection()
    test_cors()