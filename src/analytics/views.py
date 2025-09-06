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
    
    def aggregate_by_hour(self, events):
        hourly_counts = defaultdict(int)
        
        for event in events:
            timestamp = int(event.get('timestamp', 0))
            hour = datetime.fromtimestamp(timestamp / 1000).strftime('%Y-%m-%d %H:00')
            hourly_counts[hour] += 1
        
        return [{'hour': k, 'count': v} for k, v in sorted(hourly_counts.items())]
