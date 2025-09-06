# Phase 3: 핵심 기능 개발 (4시간) - 개발자 B

## 목표
이벤트 추적 스크립트, Django DynamoDB 연동, API 개발

## 작업 내용

### 1. Vanilla JS 이벤트 추적 스크립트 (120분)

**static/js/liveinsight-tracker.js**
```javascript
(function() {
    'use strict';
    
    class LiveInsightTracker {
        constructor(config) {
            this.apiUrl = config.apiUrl;
            this.userId = this.getUserId();
            this.sessionId = this.getSessionId();
            this.init();
        }
        
        init() {
            this.trackPageView();
            this.setupEventListeners();
            this.startHeartbeat();
        }
        
        getUserId() {
            let userId = localStorage.getItem('li_user_id');
            if (!userId) {
                userId = 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                localStorage.setItem('li_user_id', userId);
            }
            return userId;
        }
        
        getSessionId() {
            let sessionId = sessionStorage.getItem('li_session_id');
            if (!sessionId) {
                sessionId = 'sess_' + Date.now() + '_' + this.userId.substr(-8);
                sessionStorage.setItem('li_session_id', sessionId);
            }
            return sessionId;
        }
        
        trackPageView() {
            this.sendEvent({
                event_type: 'page_view',
                page_url: window.location.href,
                referrer: document.referrer,
                user_agent: navigator.userAgent
            });
        }
        
        trackClick(element) {
            this.sendEvent({
                event_type: 'click',
                page_url: window.location.href,
                element_tag: element.tagName,
                element_id: element.id,
                element_class: element.className,
                element_text: element.textContent.substr(0, 100)
            });
        }
        
        trackConversion(conversionType) {
            this.sendEvent({
                event_type: 'conversion',
                conversion_type: conversionType,
                page_url: window.location.href
            });
        }
        
        setupEventListeners() {
            // 클릭 이벤트 추적
            document.addEventListener('click', (e) => {
                if (e.target.tagName === 'A' || e.target.tagName === 'BUTTON') {
                    this.trackClick(e.target);
                }
            });
            
            // 페이지 이탈 추적
            window.addEventListener('beforeunload', () => {
                this.sendEvent({
                    event_type: 'page_exit',
                    page_url: window.location.href
                });
            });
        }
        
        startHeartbeat() {
            setInterval(() => {
                this.sendEvent({
                    event_type: 'heartbeat',
                    page_url: window.location.href
                });
            }, 30000); // 30초마다
        }
        
        sendEvent(eventData) {
            const payload = {
                user_id: this.userId,
                session_id: this.sessionId,
                timestamp: Date.now(),
                ...eventData
            };
            
            fetch(this.apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(payload)
            }).catch(error => {
                console.error('LiveInsight tracking error:', error);
            });
        }
    }
    
    // 전역 객체로 노출
    window.LiveInsight = {
        init: function(config) {
            window.liTracker = new LiveInsightTracker(config);
        },
        track: function(eventType, data) {
            if (window.liTracker) {
                window.liTracker.sendEvent({
                    event_type: eventType,
                    ...data
                });
            }
        },
        trackConversion: function(type) {
            if (window.liTracker) {
                window.liTracker.trackConversion(type);
            }
        }
    };
})();
```

### 2. Django DynamoDB 연동 (90분)

**analytics/dynamodb_client.py**
```python
import boto3
from django.conf import settings
from decimal import Decimal
import json

class DynamoDBClient:
    def __init__(self):
        self.dynamodb = boto3.resource(
            'dynamodb',
            region_name=settings.AWS_DEFAULT_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
        self.events_table = self.dynamodb.Table(settings.EVENTS_TABLE)
        self.sessions_table = self.dynamodb.Table(settings.SESSIONS_TABLE)
        self.active_sessions_table = self.dynamodb.Table(settings.ACTIVE_SESSIONS_TABLE)
    
    def get_active_sessions(self):
        try:
            response = self.active_sessions_table.scan()
            return response.get('Items', [])
        except Exception as e:
            print(f"Error getting active sessions: {e}")
            return []
    
    def get_session_events(self, session_id):
        try:
            response = self.events_table.query(
                IndexName='SessionIndex',
                KeyConditionExpression='session_id = :sid',
                ExpressionAttributeValues={':sid': session_id}
            )
            return response.get('Items', [])
        except Exception as e:
            print(f"Error getting session events: {e}")
            return []
    
    def get_hourly_stats(self, hours=24):
        # 시간대별 통계 조회 (간단한 구현)
        try:
            from datetime import datetime, timedelta
            end_time = datetime.now()
            start_time = end_time - timedelta(hours=hours)
            
            response = self.events_table.scan(
                FilterExpression='#ts BETWEEN :start AND :end',
                ExpressionAttributeNames={'#ts': 'timestamp'},
                ExpressionAttributeValues={
                    ':start': int(start_time.timestamp() * 1000),
                    ':end': int(end_time.timestamp() * 1000)
                }
            )
            return response.get('Items', [])
        except Exception as e:
            print(f"Error getting hourly stats: {e}")
            return []
    
    def get_page_stats(self):
        try:
            response = self.events_table.scan(
                FilterExpression='event_type = :et',
                ExpressionAttributeValues={':et': 'page_view'}
            )
            
            # 페이지별 집계
            page_counts = {}
            for item in response.get('Items', []):
                page_url = item.get('page_url', 'Unknown')
                page_counts[page_url] = page_counts.get(page_url, 0) + 1
            
            return [{'page': k, 'views': v} for k, v in page_counts.items()]
        except Exception as e:
            print(f"Error getting page stats: {e}")
            return []

# 싱글톤 인스턴스
db_client = DynamoDBClient()
```

### 3. 실시간 세션 조회 API (60분)

**analytics/views.py 업데이트**
```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .dynamodb_client import db_client
from .serializers import ActiveSessionSerializer
from datetime import datetime

class SessionViewSet(viewsets.ViewSet):
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """활성 세션 목록 조회"""
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
            return Response(serializer.data)
            
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
```

### 4. 기본 통계 API (90분)

**analytics/views.py에 통계 ViewSet 추가**
```python
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
        from collections import defaultdict
        hourly_counts = defaultdict(int)
        
        for event in events:
            timestamp = int(event.get('timestamp', 0))
            hour = datetime.fromtimestamp(timestamp / 1000).strftime('%Y-%m-%d %H:00')
            hourly_counts[hour] += 1
        
        return [{'hour': k, 'count': v} for k, v in sorted(hourly_counts.items())]

# URL 설정 업데이트
# analytics/urls.py
router.register(r'statistics', StatisticsViewSet, basename='statistics')
```

## 완료 기준
- [ ] 이벤트 추적 JavaScript 라이브러리 완성
- [ ] DynamoDB 연동 클라이언트 구현
- [ ] 실시간 세션 조회 API 완성
- [ ] 기본 통계 API 구현
- [ ] API 테스트 완료