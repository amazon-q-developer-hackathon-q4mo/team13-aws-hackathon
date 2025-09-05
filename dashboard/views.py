from django.shortcuts import render
from django.http import JsonResponse
from analytics.dynamodb_client import db_client
import json

def index(request):
    return render(request, 'dashboard/index.html')

def statistics(request):
    return render(request, 'dashboard/statistics.html')

def api_active_sessions(request):
    """활성 세션 API"""
    try:
        sessions = db_client.get_active_sessions()
        
        # 데이터 변환
        formatted_sessions = []
        for session in sessions:
            formatted_sessions.append({
                'session_id': session.get('session_id'),
                'user_id': session.get('user_id'),
                'last_activity': session.get('last_activity'),
                'current_page': session.get('current_page', ''),
                'duration': calculate_duration(session.get('last_activity'))
            })
        
        return JsonResponse(formatted_sessions, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def api_session_events(request, session_id):
    """세션별 이벤트 API"""
    try:
        events = db_client.get_session_events(session_id)
        return JsonResponse(events, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def api_hourly_stats(request):
    """시간대별 통계 API"""
    try:
        hours = int(request.GET.get('hours', 24))
        events = db_client.get_hourly_stats(hours)
        
        # 시간대별 집계
        from collections import defaultdict
        from datetime import datetime
        
        hourly_counts = defaultdict(int)
        for event in events:
            timestamp = int(event.get('timestamp', 0))
            hour = datetime.fromtimestamp(timestamp / 1000).strftime('%m-%d %H:00')
            hourly_counts[hour] += 1
        
        result = [{'hour': k, 'count': v} for k, v in sorted(hourly_counts.items())]
        return JsonResponse(result, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def api_page_stats(request):
    """페이지별 통계 API"""
    try:
        page_stats = db_client.get_page_stats()
        return JsonResponse(page_stats, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def calculate_duration(last_activity):
    if not last_activity:
        return 0
    from datetime import datetime
    current_time = int(datetime.now().timestamp() * 1000)
    return max(0, current_time - int(last_activity))
