from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.core.cache import cache
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator
from .models import Event, Session
from .serializers import EventSerializer, SessionSerializer, ActiveSessionSerializer
from .dynamodb_client import db_client
from datetime import datetime
from collections import defaultdict

class EventViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = EventSerializer
    
    def get_queryset(self):
        return Event.objects.none()

class SessionViewSet(viewsets.ViewSet):
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """활성 세션 목록 조회 (캐시 적용)"""
        cache_key = 'active_sessions'
        cached_data = cache.get(cache_key)
        
        if cached_data is not None:
            return Response(cached_data)
            
        try:
            sessions = db_client.get_active_sessions()
            
            # 데이터 변환
            active_sessions = []
            for session in sessions:
                session_data = {
                    'session_id': session.get('session_id'),
                    'user_id': session.get('user_id'),
                    'last_activity': session.get('last_activity'),
                    'current_page': session.get('current_page'),
                    'duration': self.calculate_duration(session.get('last_activity'))
                }
                active_sessions.append(session_data)
            
            serializer = ActiveSessionSerializer(active_sessions, many=True)
            response_data = serializer.data
            
            # 30초 캐시
            cache.set(cache_key, response_data, 30)
            return Response(response_data)
            
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['get'])
    def events(self, request, pk=None):
        """특정 세션의 이벤트 목록"""
        try:
            events = db_client.get_session_events(pk)
            return Response(events)
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def calculate_duration(self, last_activity):
        if not last_activity:
            return 0
        current_time = int(datetime.now().timestamp() * 1000)
        return max(0, current_time - int(last_activity))

class StatisticsViewSet(viewsets.ViewSet):
    
    @action(detail=False, methods=['get'])
    def hourly(self, request):
        """시간대별 통계"""
        try:
            hours = int(request.query_params.get('hours', 24))
            events = db_client.get_hourly_stats(hours)
            
            # 시간대별 집계
            hourly_data = self.aggregate_by_hour(events)
            return Response(hourly_data)
            
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def pages(self, request):
        """페이지별 통계"""
        try:
            page_stats = db_client.get_page_stats()
            return Response(page_stats)
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def referrers(self, request):
        """유입경로별 통계"""
        try:
            referrer_stats = db_client.get_referrer_stats()
            return Response(referrer_stats)
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """요약 통계"""
        try:
            summary_stats = db_client.get_summary_stats()
            return Response(summary_stats)
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def aggregate_by_hour(self, events):
        from datetime import datetime, timedelta, timezone as dt_timezone
        from django.utils import timezone
        
        hourly_counts = defaultdict(int)
        
        # 한국 시간 기준으로 현재 시간 가져오기
        now = timezone.localtime(timezone.now())
        hours_range = []
        
        # 100분 전부터 현재까지 5분 간격으로 라벨 생성 (20개 포인트)
        for i in range(20):
            time_point = now - timedelta(minutes=(19 - i) * 5)
            # 한국 시간대로 포맷팅
            time_key = time_point.strftime('%H:%M')
            hours_range.append((time_key, time_point))
            hourly_counts[time_key] = 0
        
        # 실제 이벤트 데이터로 카운트 업데이트
        for event in events:
            timestamp = int(event.get('timestamp', 0))
            # UTC 타임스탬프를 한국 시간대로 변환
            utc_time = datetime.fromtimestamp(timestamp / 1000, tz=dt_timezone.utc)
            event_time = timezone.localtime(utc_time)
            # 이벤트 시간을 5분 단위로 맞춤
            minute_slot = (event_time.minute // 5) * 5
            event_rounded = event_time.replace(minute=minute_slot, second=0, microsecond=0)
            time_key = event_rounded.strftime('%H:%M')
            if time_key in hourly_counts:
                hourly_counts[time_key] += 1
        
        # 시간 순서대로 정렬하여 반환
        return [{'hour': hour_key, 'count': hourly_counts[hour_key]} for hour_key, _ in hours_range]
