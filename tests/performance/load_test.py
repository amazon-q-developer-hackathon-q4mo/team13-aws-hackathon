#!/usr/bin/env python3
"""
성능 부하 테스트
동시 사용자 1000명, 초당 100개 이벤트 처리 테스트
"""

import asyncio
import aiohttp
import time
import json
import statistics
from concurrent.futures import ThreadPoolExecutor
import random

class LoadTester:
    def __init__(self, api_base_url, lambda_url, concurrent_users=100, events_per_second=10):
        self.api_base_url = api_base_url.rstrip('/')
        self.lambda_url = lambda_url
        self.concurrent_users = concurrent_users
        self.events_per_second = events_per_second
        self.results = []
        
    async def send_event(self, session, user_id, session_id):
        """단일 이벤트 전송"""
        event = {
            'user_id': user_id,
            'session_id': session_id,
            'event_type': random.choice(['page_view', 'click', 'heartbeat']),
            'page_url': f'https://example.com/page-{random.randint(1, 100)}',
            'timestamp': int(time.time() * 1000),
            'user_agent': 'LoadTest-Agent/1.0'
        }
        
        start_time = time.time()
        try:
            async with session.post(self.lambda_url, json=event) as response:
                end_time = time.time()
                response_time = (end_time - start_time) * 1000  # ms
                
                return {
                    'status_code': response.status,
                    'response_time': response_time,
                    'success': response.status == 200
                }
        except Exception as e:
            end_time = time.time()
            return {
                'status_code': 0,
                'response_time': (end_time - start_time) * 1000,
                'success': False,
                'error': str(e)
            }
    
    async def api_request(self, session, endpoint):
        """API 요청 테스트"""
        start_time = time.time()
        try:
            async with session.get(f"{self.api_base_url}{endpoint}") as response:
                end_time = time.time()
                response_time = (end_time - start_time) * 1000
                
                return {
                    'endpoint': endpoint,
                    'status_code': response.status,
                    'response_time': response_time,
                    'success': response.status == 200
                }
        except Exception as e:
            end_time = time.time()
            return {
                'endpoint': endpoint,
                'status_code': 0,
                'response_time': (end_time - start_time) * 1000,
                'success': False,
                'error': str(e)
            }
    
    async def simulate_user(self, user_id):
        """단일 사용자 시뮬레이션"""
        session_id = f'load_test_session_{user_id}_{int(time.time())}'
        user_results = []
        
        async with aiohttp.ClientSession() as session:
            # 각 사용자가 여러 이벤트 생성
            for _ in range(5):  # 사용자당 5개 이벤트
                result = await self.send_event(session, f'load_test_user_{user_id}', session_id)
                user_results.append(result)
                
                # 이벤트 간 간격
                await asyncio.sleep(random.uniform(0.1, 1.0))
        
        return user_results
    
    async def test_concurrent_users(self):
        """동시 사용자 테스트"""
        print(f"🧪 Testing {self.concurrent_users} concurrent users...")
        
        start_time = time.time()
        
        # 동시 사용자 시뮬레이션
        tasks = []
        for user_id in range(self.concurrent_users):
            task = asyncio.create_task(self.simulate_user(user_id))
            tasks.append(task)
        
        # 모든 사용자 작업 완료 대기
        results = await asyncio.gather(*tasks)
        
        end_time = time.time()
        total_time = end_time - start_time
        
        # 결과 집계
        all_results = []
        for user_results in results:
            all_results.extend(user_results)
        
        successful_requests = sum(1 for r in all_results if r['success'])
        total_requests = len(all_results)
        success_rate = (successful_requests / total_requests) * 100
        
        response_times = [r['response_time'] for r in all_results if r['success']]
        avg_response_time = statistics.mean(response_times) if response_times else 0
        p95_response_time = statistics.quantiles(response_times, n=20)[18] if len(response_times) > 20 else 0
        
        print(f"✅ Concurrent users test completed:")
        print(f"   Total time: {total_time:.2f}s")
        print(f"   Total requests: {total_requests}")
        print(f"   Successful requests: {successful_requests}")
        print(f"   Success rate: {success_rate:.2f}%")
        print(f"   Average response time: {avg_response_time:.2f}ms")
        print(f"   95th percentile: {p95_response_time:.2f}ms")
        
        return {
            'total_time': total_time,
            'total_requests': total_requests,
            'success_rate': success_rate,
            'avg_response_time': avg_response_time,
            'p95_response_time': p95_response_time
        }
    
    async def test_api_performance(self):
        """API 성능 테스트"""
        print("🧪 Testing API performance...")
        
        endpoints = [
            '/api/sessions/active/',
            '/api/statistics/hourly/',
            '/api/statistics/pages/',
            '/health/'
        ]
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            
            # 각 엔드포인트를 동시에 여러 번 호출
            for endpoint in endpoints:
                for _ in range(20):  # 각 엔드포인트당 20회
                    task = asyncio.create_task(self.api_request(session, endpoint))
                    tasks.append(task)
            
            results = await asyncio.gather(*tasks)
        
        # 엔드포인트별 결과 분석
        endpoint_stats = {}
        for result in results:
            endpoint = result['endpoint']
            if endpoint not in endpoint_stats:
                endpoint_stats[endpoint] = []
            endpoint_stats[endpoint].append(result)
        
        print("📊 API Performance Results:")
        for endpoint, stats in endpoint_stats.items():
            successful = [s for s in stats if s['success']]
            if successful:
                avg_time = statistics.mean([s['response_time'] for s in successful])
                success_rate = (len(successful) / len(stats)) * 100
                print(f"   {endpoint}: {avg_time:.2f}ms avg, {success_rate:.1f}% success")
        
        return endpoint_stats

def main():
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python load_test.py <api_base_url> <lambda_url> [concurrent_users] [events_per_second]")
        sys.exit(1)
    
    api_base_url = sys.argv[1]
    lambda_url = sys.argv[2]
    concurrent_users = int(sys.argv[3]) if len(sys.argv) > 3 else 100
    events_per_second = int(sys.argv[4]) if len(sys.argv) > 4 else 10
    
    tester = LoadTester(api_base_url, lambda_url, concurrent_users, events_per_second)
    
    async def run_tests():
        try:
            print("🚀 Starting load tests...")
            
            # 동시 사용자 테스트
            user_results = await tester.test_concurrent_users()
            
            # API 성능 테스트
            api_results = await tester.test_api_performance()
            
            # 성능 목표 검증
            print("\n📋 Performance Goals Verification:")
            
            # API 응답 시간: 평균 200ms 이하
            if user_results['avg_response_time'] <= 200:
                print("✅ API response time goal met (≤200ms)")
            else:
                print(f"❌ API response time goal not met ({user_results['avg_response_time']:.2f}ms > 200ms)")
            
            # 성공률: 99% 이상
            if user_results['success_rate'] >= 99:
                print("✅ Success rate goal met (≥99%)")
            else:
                print(f"❌ Success rate goal not met ({user_results['success_rate']:.2f}% < 99%)")
            
            print("🎉 Load tests completed!")
            
        except Exception as e:
            print(f"❌ Load test failed: {str(e)}")
            sys.exit(1)
    
    asyncio.run(run_tests())

if __name__ == "__main__":
    main()