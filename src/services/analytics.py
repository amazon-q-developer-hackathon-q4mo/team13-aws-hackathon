from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import defaultdict
from src.services.dynamodb import DynamoDBService
from src.models.sessions import SessionStats

class AnalyticsService:
    def __init__(self):
        self.db = DynamoDBService()
    
    async def get_realtime_stats(self) -> Dict[str, Any]:
        """
        최근 이벤트를 기반으로 실시간 웹사이트 통계를 계산하여 반환
        
        DynamoDB에서 최근 1000개 이벤트를 조회하여 다양한 통계 지표를 실시간으로 계산합니다.
        페이지뷰, 클릭 수, 시간대별 분포, 인기 페이지 등의 정보를 제공합니다.
        
        Returns:
            Dict[str, Any]: 실시간 통계 데이터
                - total_events: 총 이벤트 수
                - page_views: 페이지뷰 수
                - clicks: 클릭 수
                - hourly_distribution: 시간대별 이벤트 분포
                - popular_pages: 인기 페이지 상위 10개
                - last_updated: 마지막 업데이트 시간
        
        Raises:
            Exception: 데이터베이스 조회 또는 통계 계산 중 오류 발생 시
        
        Note:
            - 시간대별 분포는 24시간 형식 (HH:00)으로 제공
            - 인기 페이지는 페이지뷰 수 기준 내림차순 정렬
            - 잘못된 timestamp 형식의 이벤트는 무시됨
        """
        events = await self.db.get_recent_events(limit=1000)
        
        # 기본 통계 계산
        total_events = len(events)
        page_views = len([e for e in events if e.get('event_type') == 'page_view'])
        clicks = len([e for e in events if e.get('event_type') == 'click'])
        
        # 시간대별 이벤트 분포
        hourly_events = defaultdict(int)
        for event in events:
            try:
                timestamp = datetime.fromisoformat(event.get('timestamp', ''))
                hour = timestamp.strftime('%H:00')
                hourly_events[hour] += 1
            except:
                continue
        
        # 인기 페이지
        page_counts = defaultdict(int)
        for event in events:
            if event.get('event_type') == 'page_view':
                url = event.get('url', '')
                page_counts[url] += 1
        
        popular_pages = sorted(page_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        
        return {
            'total_events': total_events,
            'page_views': page_views,
            'clicks': clicks,
            'hourly_distribution': dict(hourly_events),
            'popular_pages': [{'url': url, 'views': count} for url, count in popular_pages],
            'last_updated': datetime.utcnow().isoformat()
        }
    
    async def get_session_analytics(self) -> SessionStats:
        """
        사용자 세션 관련 분석 데이터를 계산하여 반환
        
        현재는 목 데이터를 반환하지만, 실제 구현에서는 DynamoDB에서
        세션 데이터를 조회하여 실제 통계를 계산합니다.
        
        Returns:
            SessionStats: 세션 통계 데이터 모델
                - total_sessions: 총 세션 수
                - active_sessions: 활성 세션 수
                - avg_duration: 평균 세션 지속시간(초)
                - avg_page_views: 세션당 평균 페이지뷰
                - bounce_rate: 이탈률 (0.0-1.0)
        
        Note:
            - 활성 세션: 마지막 활동이 30분 이내인 세션
            - 이탈률: 한 페이지만 보고 떠난 세션의 비율
            - 향후 실제 DB 조회 로직으로 교체 예정
        """
        # 실제 구현에서는 DynamoDB에서 세션 데이터를 조회
        return SessionStats(
            total_sessions=150,
            active_sessions=23,
            avg_duration=245.5,
            avg_page_views=3.2,
            bounce_rate=0.35
        )