from django.shortcuts import render
from django.http import JsonResponse, HttpResponse
from django.views.static import serve
from django.conf import settings
import os
from django.utils import timezone
from analytics.dynamodb_client import db_client
from datetime import datetime, timedelta
from collections import defaultdict
import json
import pytz


def calculate_duration(last_activity):
    """마지막 활동 시간으로부터 경과 시간 계산 (밀리초)"""
    if not last_activity:
        return 0
    current_time = int(timezone.now().timestamp() * 1000)
    return max(0, current_time - int(last_activity))


def index(request):
    return render(request, 'dashboard/index.html')


def statistics(request):
    return render(request, 'dashboard/index.html')


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
        hourly_counts = defaultdict(int)

        # 로컬 타임존 기준 현재 시간
        now = timezone.now()
        now_local = now.astimezone(timezone.get_current_timezone())
        hours_range = []

        # 100분 전부터 현재까지 5분 간격으로 라벨 생성 (20개 포인트)
        for i in range(20):
            time_point = now_local - timedelta(minutes=(19 - i) * 5)
            time_key = time_point.strftime('%H:%M')
            hours_range.append(time_key)
            hourly_counts[time_key] = 0

        # 실제 이벤트 데이터로 카운트 업데이트
        for event in events:
            timestamp = int(event.get('timestamp', 0))
            # UTC 타임스탬프를 서버 타임존으로 변환하여 표시
            utc_time = datetime.fromtimestamp(timestamp / 1000, tz=pytz.UTC)
            local_time = utc_time.astimezone(timezone.get_current_timezone())

            # 100분 이내 데이터만 포함
            time_diff = (now - local_time).total_seconds()
            if time_diff <= 100 * 60 and time_diff >= 0:
                # 이벤트 시간을 5분 단위로 맞춤
                minute_slot = (local_time.minute // 5) * 5
                event_rounded = local_time.replace(minute=minute_slot, second=0, microsecond=0)
                time_key = event_rounded.strftime('%H:%M')
                if time_key in hourly_counts:
                    hourly_counts[time_key] += 1

        # 최근 20개 포인트만 반환 (현재 시간이 마지막)
        result = [{'hour': hour_key, 'count': hourly_counts[hour_key]} for hour_key in hours_range[-20:]]
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


def api_hourly_details(request):
    """특정 시간대 상세 데이터 API"""
    try:
        hour = request.GET.get('hour')  # 'HH:MM' 형식
        if not hour:
            return JsonResponse({'error': 'hour parameter required'}, status=400)

        # 해당 시간대의 이벤트 조회
        events = db_client.get_hourly_stats(24)

        # 해당 시간대 필터링
        filtered_events = []
        for event in events:
            timestamp = int(event.get('timestamp', 0))
            # UTC 타임스탬프를 서버 타임존으로 변환
            utc_time = datetime.fromtimestamp(timestamp / 1000, tz=pytz.UTC)
            local_time = utc_time.astimezone(timezone.get_current_timezone())
            event_hour = local_time.strftime('%H:%M')

            if event_hour == hour:
                filtered_events.append({
                    'event_id': event.get('event_id'),
                    'user_id': event.get('user_id'),
                    'session_id': event.get('session_id'),
                    'event_type': event.get('event_type'),
                    'page_url': event.get('page_url'),
                    'timestamp': event.get('timestamp'),
                    'formatted_time': local_time.strftime('%H:%M:%S')
                })

        return JsonResponse({
            'hour': hour,
            'total_events': len(filtered_events),
            'events': filtered_events[:20]  # 최대 20개만 반환
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def api_page_details(request):
    """특정 페이지 상세 데이터 API"""
    try:
        page_url = request.GET.get('page')
        if not page_url:
            return JsonResponse({'error': 'page parameter required'}, status=400)

        # 해당 페이지의 이벤트 조회
        events = db_client.get_hourly_stats(24)

        # 해당 페이지 필터링
        filtered_events = []
        for event in events:
            if event.get('page_url') == page_url and event.get('event_type') == 'page_view':
                timestamp = int(event.get('timestamp', 0))
                # UTC 타임스탬프를 서버 타임존으로 변환
                utc_time = datetime.fromtimestamp(timestamp / 1000, tz=pytz.UTC)
                local_time = utc_time.astimezone(timezone.get_current_timezone())

                filtered_events.append({
                    'event_id': event.get('event_id'),
                    'user_id': event.get('user_id'),
                    'session_id': event.get('session_id'),
                    'timestamp': event.get('timestamp'),
                    'formatted_time': local_time.strftime('%H:%M:%S'),
                    'referrer': event.get('referrer', '')
                })

        # 시간대별 분포
        hourly_distribution = defaultdict(int)
        for event in filtered_events:
            timestamp = int(event.get('timestamp', 0))
            utc_time = datetime.fromtimestamp(timestamp / 1000, tz=pytz.UTC)
            local_time = utc_time.astimezone(timezone.get_current_timezone())
            hour_key = local_time.strftime('%H:00')
            hourly_distribution[hour_key] += 1

        return JsonResponse({
            'page_url': page_url,
            'total_views': len(filtered_events),
            'recent_events': filtered_events[:10],  # 최근 10개
            'hourly_distribution': dict(hourly_distribution)
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def api_referrer_details(request):
    """유입경로 상세 데이터 API"""
    try:
        referrer = request.GET.get('referrer')
        if not referrer:
            return JsonResponse({'error': 'referrer parameter required'}, status=400)

        # 해당 유입경로의 이벤트 조회
        events = db_client.get_hourly_stats(168)  # 7일간 데이터

        # 해당 유입경로 필터링
        filtered_events = []
        for event in events:
            if event.get('event_type') == 'page_view':
                event_referrer = event.get('referrer', '')

                # 유입경로 매칭 로직
                matched = False
                if referrer == '직접 접속' and not event_referrer:
                    matched = True
                elif 'google' in referrer.lower() and 'google' in event_referrer.lower():
                    matched = True
                elif 'facebook' in referrer.lower() and 'facebook' in event_referrer.lower():
                    matched = True
                elif 'twitter' in referrer.lower() and 'twitter' in event_referrer.lower():
                    matched = True
                elif referrer.lower() in event_referrer.lower():
                    matched = True

                if matched:
                    timestamp = int(event.get('timestamp', 0))
                    utc_time = datetime.fromtimestamp(timestamp / 1000, tz=pytz.UTC)
                    local_time = utc_time.astimezone(timezone.get_current_timezone())

                    filtered_events.append({
                        'event_id': event.get('event_id'),
                        'user_id': event.get('user_id'),
                        'session_id': event.get('session_id'),
                        'timestamp': event.get('timestamp'),
                        'formatted_time': local_time.strftime('%m/%d %H:%M'),
                        'landing_page': event.get('page_url', '')
                    })

        # 시간대별 분포
        hourly_distribution = defaultdict(int)
        for event in filtered_events:
            timestamp = int(event.get('timestamp', 0))
            utc_time = datetime.fromtimestamp(timestamp / 1000, tz=pytz.UTC)
            local_time = utc_time.astimezone(timezone.get_current_timezone())
            hour_key = local_time.strftime('%H:00')
            hourly_distribution[hour_key] += 1

        return JsonResponse({
            'referrer': referrer,
            'total_visitors': len(filtered_events),
            'recent_visits': filtered_events[:10],  # 최근 10개
            'hourly_distribution': dict(hourly_distribution)
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def calculate_duration(last_activity):
    if not last_activity:
        return 0
    # UTC 기준으로 계산 (저장된 데이터가 UTC이므로)
    current_time = int(timezone.now().timestamp() * 1000)
    return max(0, current_time - int(last_activity))