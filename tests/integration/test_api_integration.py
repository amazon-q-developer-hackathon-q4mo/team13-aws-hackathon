#!/usr/bin/env python3
"""
Django REST API와 DynamoDB 연동 테스트
"""

import requests
import json
import time
import boto3

class APIIntegrationTest:
    def __init__(self, api_base_url, aws_region='us-east-1'):
        self.api_base_url = api_base_url.rstrip('/')
        self.aws_region = aws_region
        self.dynamodb = boto3.client('dynamodb', region_name=aws_region)
        
    def test_cors_settings(self):
        """CORS 설정 테스트"""
        print("🧪 Testing CORS settings...")
        
        # OPTIONS 요청으로 CORS 헤더 확인
        response = requests.options(
            f"{self.api_base_url}/api/sessions/active/",
            headers={'Origin': 'https://example.com'}
        )
        
        assert 'Access-Control-Allow-Origin' in response.headers, "CORS not configured"
        print("✅ CORS settings working correctly")
        
    def test_api_endpoints(self):
        """API 엔드포인트 테스트"""
        print("🧪 Testing API endpoints...")
        
        endpoints = [
            '/api/sessions/active/',
            '/api/statistics/hourly/',
            '/api/statistics/pages/',
            '/health/'
        ]
        
        for endpoint in endpoints:
            response = requests.get(f"{self.api_base_url}{endpoint}")
            assert response.status_code == 200, f"Endpoint {endpoint} failed"
            
            # JSON 응답 확인
            if endpoint != '/health/':
                data = response.json()
                assert isinstance(data, (list, dict)), f"Invalid JSON response from {endpoint}"
                
        print("✅ All API endpoints working correctly")
        
    def test_data_consistency(self):
        """데이터 일관성 테스트"""
        print("🧪 Testing data consistency...")
        
        # 테스트 데이터 생성
        test_user = f'consistency_test_{int(time.time())}'
        
        # DynamoDB에 직접 테스트 데이터 삽입
        self.dynamodb.put_item(
            TableName='LiveInsight-ActiveSessions',
            Item={
                'session_id': {'S': f'test_session_{int(time.time())}'},
                'user_id': {'S': test_user},
                'last_activity': {'N': str(int(time.time() * 1000))},
                'current_page': {'S': 'https://example.com/consistency-test'},
                'ttl': {'N': str(int(time.time()) + 1800)}
            }
        )
        
        time.sleep(2)
        
        # API를 통해 데이터 조회
        response = requests.get(f"{self.api_base_url}/api/sessions/active/")
        sessions = response.json()
        
        # 테스트 데이터 확인
        test_session_found = any(s.get('user_id') == test_user for s in sessions)
        assert test_session_found, "Data consistency issue detected"
        
        print("✅ Data consistency verified")
        
    def test_pagination(self):
        """페이지네이션 테스트"""
        print("🧪 Testing pagination...")
        
        response = requests.get(f"{self.api_base_url}/api/sessions/active/?page=1")
        assert response.status_code == 200, "Pagination failed"
        
        data = response.json()
        # DRF 페이지네이션 구조 확인
        if isinstance(data, dict) and 'results' in data:
            assert 'count' in data, "Pagination metadata missing"
            assert 'results' in data, "Pagination results missing"
            
        print("✅ Pagination working correctly")

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python test_api_integration.py <api_base_url>")
        sys.exit(1)
        
    api_base_url = sys.argv[1]
    
    tester = APIIntegrationTest(api_base_url)
    
    try:
        tester.test_cors_settings()
        tester.test_api_endpoints()
        tester.test_data_consistency()
        tester.test_pagination()
        print("🎉 All API integration tests passed!")
    except Exception as e:
        print(f"❌ API integration test failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()