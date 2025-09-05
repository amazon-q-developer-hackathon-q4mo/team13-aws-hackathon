#!/usr/bin/env python3
import asyncio
import aiohttp
import time
import json
import uuid
from datetime import datetime

class LoadTester:
    def __init__(self, api_url, concurrent_users=10):
        self.api_url = api_url
        self.concurrent_users = concurrent_users
        self.results = []
        self.start_time = None
    
    async def send_event(self, session, event_data):
        start_time = time.time()
        try:
            async with session.post(self.api_url, json=event_data, timeout=30) as response:
                end_time = time.time()
                response_text = await response.text()
                self.results.append({
                    'status': response.status,
                    'response_time': end_time - start_time,
                    'success': response.status == 200,
                    'timestamp': start_time
                })
        except Exception as e:
            end_time = time.time()
            self.results.append({
                'status': 0,
                'response_time': end_time - start_time,
                'success': False,
                'error': str(e),
                'timestamp': start_time
            })
    
    def generate_event_data(self, user_index, event_index):
        """테스트 이벤트 데이터 생성"""
        pages = ['/home', '/products', '/about', '/contact', '/pricing']
        event_types = ['page_view', 'click', 'scroll']
        
        return {
            'user_id': f'load_test_user_{user_index}',
            'event_type': event_types[event_index % len(event_types)],
            'page_url': f'https://example.com{pages[event_index % len(pages)]}',
            'referrer': 'https://google.com',
            'user_agent': 'LoadTest/1.0'
        }
    
    async def run_test(self, duration_seconds=60):
        """부하 테스트 실행"""
        print(f"🚀 부하 테스트 시작...")
        print(f"📊 설정: {self.concurrent_users}명 동시 사용자, {duration_seconds}초 지속")
        print(f"🎯 대상: {self.api_url}")
        print("-" * 60)
        
        self.start_time = time.time()
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            end_time = time.time() + duration_seconds
            event_counter = 0
            
            while time.time() < end_time:
                # 동시 사용자 수만큼 태스크 유지
                if len([t for t in tasks if not t.done()]) < self.concurrent_users:
                    user_index = event_counter % 100  # 100명의 가상 사용자
                    event_data = self.generate_event_data(user_index, event_counter)
                    
                    task = asyncio.create_task(self.send_event(session, event_data))
                    tasks.append(task)
                    event_counter += 1
                
                # 완료된 태스크 정리
                tasks = [t for t in tasks if not t.done()]
                await asyncio.sleep(0.1)
            
            # 남은 태스크 완료 대기
            print("⏳ 남은 요청 완료 대기 중...")
            await asyncio.gather(*[t for t in tasks if not t.done()], return_exceptions=True)
    
    def analyze_results(self):
        """결과 분석 및 출력"""
        if not self.results:
            print("❌ 테스트 결과가 없습니다.")
            return
        
        total_requests = len(self.results)
        successful_requests = sum(1 for r in self.results if r['success'])
        failed_requests = total_requests - successful_requests
        
        response_times = [r['response_time'] for r in self.results if r['success']]
        
        if response_times:
            avg_response_time = sum(response_times) / len(response_times)
            min_response_time = min(response_times)
            max_response_time = max(response_times)
            
            # 백분위수 계산
            sorted_times = sorted(response_times)
            p50 = sorted_times[int(len(sorted_times) * 0.5)]
            p95 = sorted_times[int(len(sorted_times) * 0.95)]
            p99 = sorted_times[int(len(sorted_times) * 0.99)]
        else:
            avg_response_time = min_response_time = max_response_time = 0
            p50 = p95 = p99 = 0
        
        # 처리량 계산
        test_duration = max(r['timestamp'] for r in self.results) - min(r['timestamp'] for r in self.results)
        throughput = successful_requests / test_duration if test_duration > 0 else 0
        
        print("\n" + "=" * 60)
        print("📈 부하 테스트 결과")
        print("=" * 60)
        print(f"📊 총 요청 수: {total_requests:,}")
        print(f"✅ 성공 요청: {successful_requests:,}")
        print(f"❌ 실패 요청: {failed_requests:,}")
        print(f"📈 성공률: {successful_requests/total_requests*100:.2f}%")
        print(f"⚡ 처리량: {throughput:.2f} req/sec")
        print()
        print("⏱️ 응답 시간 통계:")
        print(f"   평균: {avg_response_time*1000:.0f}ms")
        print(f"   최소: {min_response_time*1000:.0f}ms")
        print(f"   최대: {max_response_time*1000:.0f}ms")
        print(f"   50%: {p50*1000:.0f}ms")
        print(f"   95%: {p95*1000:.0f}ms")
        print(f"   99%: {p99*1000:.0f}ms")
        
        # 에러 분석
        if failed_requests > 0:
            print(f"\n🚨 에러 분석:")
            error_counts = {}
            for r in self.results:
                if not r['success']:
                    error_key = f"HTTP {r['status']}" if r['status'] > 0 else "Network Error"
                    error_counts[error_key] = error_counts.get(error_key, 0) + 1
            
            for error, count in error_counts.items():
                print(f"   {error}: {count}회")

async def main():
    """메인 테스트 실행"""
    api_url = "https://qnwoi1ardd.execute-api.us-east-1.amazonaws.com/prod/events"
    
    # 테스트 시나리오들
    test_scenarios = [
        {"users": 5, "duration": 30, "name": "가벼운 부하"},
        {"users": 10, "duration": 60, "name": "중간 부하"},
        {"users": 20, "duration": 60, "name": "높은 부하"}
    ]
    
    for i, scenario in enumerate(test_scenarios, 1):
        print(f"\n🎯 시나리오 {i}: {scenario['name']}")
        
        tester = LoadTester(api_url, concurrent_users=scenario['users'])
        await tester.run_test(duration_seconds=scenario['duration'])
        tester.analyze_results()
        
        if i < len(test_scenarios):
            print(f"\n⏸️ 다음 시나리오까지 10초 대기...")
            await asyncio.sleep(10)

if __name__ == "__main__":
    asyncio.run(main())