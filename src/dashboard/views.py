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

def api_summary_stats(request):
    """요약 통계 API"""
    try:
        # 활성 세션 수
        active_sessions = db_client.get_active_sessions()
        total_sessions = len(active_sessions)
        
        # 총 이벤트 수 (최근 24시간)
        events = db_client.get_hourly_stats(24)
        total_events = len(events)
        
        # 평균 세션 시간 계산
        if active_sessions:
            total_duration = sum(calculate_duration(s.get('last_activity')) for s in active_sessions)
            avg_duration = total_duration / len(active_sessions)
            avg_minutes = int(avg_duration / 60000)
            avg_seconds = int((avg_duration % 60000) / 1000)
            avg_session_time = f"{avg_minutes}분 {avg_seconds}초"
        else:
            avg_session_time = "0분 0초"
        
        # 전환율 계산
        conversion_events = [e for e in events if e.get('event_type') == 'conversion']
        conversion_rate = f"{(len(conversion_events) / max(total_events, 1) * 100):.1f}%" if total_events > 0 else "0.0%"
        
        return JsonResponse({
            'total_sessions': f"{total_sessions:,}",
            'total_events': f"{total_events:,}",
            'avg_session_time': avg_session_time,
            'conversion_rate': conversion_rate
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def api_referrer_stats(request):
    """유입 경로 통계 API"""
    try:
        events = db_client.get_hourly_stats(168)  # 7일간 데이터
        
        # 리퍼러별 집계
        referrer_counts = {}
        for event in events:
            if event.get('event_type') == 'page_view':
                referrer = event.get('referrer', '')
                if not referrer:
                    referrer = 'Direct'
                elif 'google' in referrer.lower():
                    referrer = 'Google'
                elif 'facebook' in referrer.lower():
                    referrer = 'Facebook'
                elif 'twitter' in referrer.lower():
                    referrer = 'Twitter'
                else:
                    referrer = 'Other'
                
                referrer_counts[referrer] = referrer_counts.get(referrer, 0) + 1
        
        # 상위 5개 리퍼러
        sorted_referrers = sorted(referrer_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        
        return JsonResponse({
            'labels': [item[0] for item in sorted_referrers],
            'data': [item[1] for item in sorted_referrers]
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def calculate_duration(last_activity):
    if not last_activity:
        return 0
    from datetime import datetime
    current_time = int(datetime.now().timestamp() * 1000)
    return max(0, current_time - int(last_activity))
