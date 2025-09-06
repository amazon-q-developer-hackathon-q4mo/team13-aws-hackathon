# Phase 2: 기본 구조 구축 (2시간) - 개발자 B

## 목표
Django 모델 설계, DRF 설정, 프론트엔드 기본 템플릿 구성

## 작업 내용

### 1. Django 모델 및 시리얼라이저 (60분)

**analytics/models.py**
```python
from django.db import models
from datetime import datetime

class Event(models.Model):
    event_id = models.CharField(max_length=100, primary_key=True)
    timestamp = models.BigIntegerField()
    user_id = models.CharField(max_length=100)
    session_id = models.CharField(max_length=100)
    event_type = models.CharField(max_length=50)
    page_url = models.URLField(blank=True)
    referrer = models.URLField(blank=True)
    user_agent = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    
    class Meta:
        managed = False  # DynamoDB 사용

class Session(models.Model):
    session_id = models.CharField(max_length=100, primary_key=True)
    user_id = models.CharField(max_length=100)
    start_time = models.BigIntegerField()
    last_activity = models.BigIntegerField()
    is_active = models.BooleanField(default=True)
    entry_page = models.URLField(blank=True)
    exit_page = models.URLField(blank=True)
    referrer = models.URLField(blank=True)
    total_events = models.IntegerField(default=0)
    session_duration = models.IntegerField(default=0)
    
    class Meta:
        managed = False  # DynamoDB 사용
```

**analytics/serializers.py**
```python
from rest_framework import serializers
from .models import Event, Session

class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = '__all__'

class SessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Session
        fields = '__all__'

class ActiveSessionSerializer(serializers.Serializer):
    session_id = serializers.CharField()
    user_id = serializers.CharField()
    last_activity = serializers.IntegerField()
    current_page = serializers.URLField()
    duration = serializers.IntegerField()
```

**analytics/views.py**
```python
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
```

### 2. 프론트엔드 기본 템플릿 (60분)

**dashboard/templates/base.html**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LiveInsight Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="/">LiveInsight</a>
            <div class="navbar-nav">
                <a class="nav-link" href="/">실시간 모니터링</a>
                <a class="nav-link" href="/statistics">통계</a>
            </div>
        </div>
    </nav>
    
    <div class="container mt-4">
        {% block content %}
        {% endblock %}
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

**dashboard/templates/dashboard/index.html**
```html
{% extends 'base.html' %}

{% block content %}
<div class="row">
    <div class="col-12">
        <h2>실시간 활성 세션</h2>
        <div id="active-sessions">
            <!-- 활성 세션 목록 -->
        </div>
    </div>
</div>

<div class="row mt-4">
    <div class="col-md-6">
        <h3>시간대별 유입</h3>
        <canvas id="hourlyChart"></canvas>
    </div>
    <div class="col-md-6">
        <h3>페이지별 조회수</h3>
        <canvas id="pageChart"></canvas>
    </div>
</div>

<script>
// TODO: 차트 초기화 및 데이터 로딩
</script>
{% endblock %}
```

**dashboard/views.py**
```python
from django.shortcuts import render
from django.http import JsonResponse

def index(request):
    return render(request, 'dashboard/index.html')

def statistics(request):
    return render(request, 'dashboard/statistics.html')

def api_active_sessions(request):
    # 활성 세션 데이터는 Phase 3에서 구현
    return JsonResponse({'sessions': []})
```

**URL 설정**
```python
# analytics/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet, SessionViewSet

router = DefaultRouter()
router.register(r'events', EventViewSet, basename='event')
router.register(r'sessions', SessionViewSet, basename='session')

urlpatterns = [
    path('', include(router.urls)),
]

# dashboard/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('statistics/', views.statistics, name='statistics'),
    path('api/active-sessions/', views.api_active_sessions, name='api_active_sessions'),
]
```

## 완료 기준
- [ ] Django 모델 설계 완료
- [ ] DRF 시리얼라이저 및 ViewSet 구조 완성
- [ ] 기본 HTML 템플릿 구성
- [ ] Bootstrap 및 Chart.js 설정
- [ ] URL 라우팅 완료