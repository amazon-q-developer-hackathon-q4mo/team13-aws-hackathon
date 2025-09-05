from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Event, Session
from .serializers import EventSerializer, SessionSerializer, ActiveSessionSerializer

class EventViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = EventSerializer
    
    def get_queryset(self):
        # DynamoDB 연동은 Phase 3에서 구현
        return Event.objects.none()

class SessionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = SessionSerializer
    
    def get_queryset(self):
        # DynamoDB 연동은 Phase 3에서 구현
        return Session.objects.none()
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        # 활성 세션 조회는 Phase 3에서 구현
        return Response([])
