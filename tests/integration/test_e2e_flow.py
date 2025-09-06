#!/usr/bin/env python3
"""
End-to-End 통합 테스트
JavaScript 추적 → Lambda → DynamoDB → Django API 플로우 테스트
"""

import json
import time
import requests
import boto3
from datetime import datetime, timedelta

class E2EFlowTest:
    def __init__(self, api_base_url, lambda_url, aws_region='us-east-1'):
        self.api_base_url = api_base_url.rstrip('/')
        self.lambda_url = lambda_url
        self.aws_region = aws_region
        self.dynamodb = boto3.client('dynamodb', region_name=aws_region)
        
    def test_complete_flow(self):
        """완전한 E2E 플로우 테스트"""
        print("🧪 Starting E2E flow test...")
        
        # 1. 이벤트 데이터 생성
        test_event = {
            'user_id': f'test_user_{int(time.time())}',
            'session_id': f'test_session_{int(time.time())}',
            'event_type': 'page_view',
            'page_url': 'https://example.com/test',
            'timestamp': int(time.time() * 1000),
            'user_agent': 'E2E-Test-Agent/1.0'
        }
        
        # 2. Lambda 함수로 이벤트 전송
        print("📤 Sending event to Lambda...")
        response = requests.post(
            self.lambda_url,
            json=test_event,
            headers={'Content-Type': 'application/json'}
        )
        assert response.status_code == 200, f"Lambda failed: {response.text}"
        print("✅ Event sent to Lambda successfully")
        
        # 3. DynamoDB에 데이터 저장 확인 (잠시 대기)
        time.sleep(5)
        print("🔍 Checking DynamoDB storage...")
        
        # Events 테이블 확인
        events_response = self.dynamodb.query(
            TableName='LiveInsight-Events',
            KeyConditionExpression='user_id = :uid',
            ExpressionAttributeValues={':uid': {'S': test_event['user_id']}}
        )
        assert events_response['Count'] > 0, "Event not found in DynamoDB"
        print("✅ Event stored in DynamoDB")
        
        # 4. Django API로 데이터 조회
        print("📊 Testing Django API...")
        
        # 활성 세션 조회
        sessions_response = requests.get(f"{self.api_base_url}/api/sessions/active/")
        assert sessions_response.status_code == 200, "Sessions API failed"
        
        sessions_data = sessions_response.json()
        test_session_found = any(
            s.get('session_id') == test_event['session_id'] 
            for s in sessions_data
        )
        assert test_session_found, "Test session not found in API response"
        print("✅ Session data retrieved via Django API")
        
        # 5. 대시보드 접근 테스트
        print("🖥️  Testing dashboard access...")
        dashboard_response = requests.get(f"{self.api_base_url}/")
        assert dashboard_response.status_code == 200, "Dashboard not accessible"
        print("✅ Dashboard accessible")
        
        print("🎉 E2E flow test completed successfully!")
        return True
        
    def test_session_management(self):
        """세션 관리 및 TTL 테스트"""
        print("🧪 Testing session management...")
        
        session_id = f'ttl_test_session_{int(time.time())}'
        user_id = f'ttl_test_user_{int(time.time())}'
        
        # 세션 생성 이벤트
        event = {
            'user_id': user_id,
            'session_id': session_id,
            'event_type': 'page_view',
            'page_url': 'https://example.com/ttl-test',
            'timestamp': int(time.time() * 1000)
        }
        
        # Lambda로 이벤트 전송
        response = requests.post(self.lambda_url, json=event)
        assert response.status_code == 200
        
        time.sleep(3)
        
        # ActiveSessions 테이블에서 세션 확인
        active_response = self.dynamodb.get_item(
            TableName='LiveInsight-ActiveSessions',
            Key={'session_id': {'S': session_id}}
        )
        
        assert 'Item' in active_response, "Active session not created"
        
        # TTL 값 확인
        ttl_value = int(active_response['Item']['ttl']['N'])
        expected_ttl = int(time.time()) + 1800  # 30분
        assert abs(ttl_value - expected_ttl) < 60, "TTL not set correctly"
        
        print("✅ Session management and TTL working correctly")
        return True
        
    def test_error_handling(self):
        """에러 처리 테스트"""
        print("🧪 Testing error handling...")
        
        # 잘못된 데이터로 테스트
        invalid_event = {
            'invalid_field': 'test'
        }
        
        response = requests.post(self.lambda_url, json=invalid_event)
        # Lambda는 에러를 처리하고 적절한 응답을 반환해야 함
        assert response.status_code in [200, 400], "Error handling failed"
        
        print("✅ Error handling working correctly")
        return True

def main():
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python test_e2e_flow.py <api_base_url> <lambda_url>")
        sys.exit(1)
        
    api_base_url = sys.argv[1]
    lambda_url = sys.argv[2]
    
    tester = E2EFlowTest(api_base_url, lambda_url)
    
    try:
        tester.test_complete_flow()
        tester.test_session_management()
        tester.test_error_handling()
        print("🎉 All E2E tests passed!")
    except Exception as e:
        print(f"❌ E2E test failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()