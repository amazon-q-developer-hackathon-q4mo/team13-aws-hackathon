# Phase 4: 대시보드 구현 (3시간) - 개발자 B

## 목표
실시간 대시보드 UI 구현, 차트 시각화, API 연동

## 작업 내용

### 1. 실시간 세션 목록 화면 (90분)

**dashboard/templates/dashboard/index.html 완성**
```html
{% extends 'base.html' %}

{% block content %}
<div class="row">
    <div class="col-12">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2>실시간 활성 세션</h2>
            <div>
                <span class="badge bg-success" id="active-count">0</span> 활성 사용자
                <button class="btn btn-sm btn-outline-primary ms-2" onclick="refreshSessions()">
                    <i class="fas fa-sync-alt"></i> 새로고침
                </button>
            </div>
        </div>
        
        <div class="card">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover" id="sessions-table">
                        <thead>
                            <tr>
                                <th>사용자 ID</th>
                                <th>세션 ID</th>
                                <th>현재 페이지</th>
                                <th>활동 시간</th>
                                <th>지속 시간</th>
                                <th>액션</th>
                            </tr>
                        </thead>
                        <tbody id="sessions-tbody">
                            <!-- 동적으로 채워짐 -->
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- 세션 상세 모달 -->
<div class="modal fade" id="sessionModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">세션 상세 정보</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="session-details">
                <!-- 세션 상세 정보 -->
            </div>
        </div>
    </div>
</div>

<script>
let sessionsData = [];
let refreshInterval;

// 페이지 로드 시 초기화
document.addEventListener('DOMContentLoaded', function() {
    loadActiveSessions();
    startAutoRefresh();
});

// 활성 세션 로드
async function loadActiveSessions() {
    try {
        const response = await fetch('/api/sessions/active/');
        const data = await response.json();
        sessionsData = data;
        renderSessionsTable(data);
        updateActiveCount(data.length);
    } catch (error) {
        console.error('Error loading sessions:', error);
        showError('세션 데이터를 불러오는데 실패했습니다.');
    }
}

// 세션 테이블 렌더링
function renderSessionsTable(sessions) {
    const tbody = document.getElementById('sessions-tbody');
    tbody.innerHTML = '';
    
    sessions.forEach(session => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${session.user_id}</td>
            <td><code>${session.session_id.substring(0, 12)}...</code></td>
            <td><a href="${session.current_page}" target="_blank">${truncateUrl(session.current_page)}</a></td>
            <td>${formatTimestamp(session.last_activity)}</td>
            <td>${formatDuration(session.duration)}</td>
            <td>
                <button class="btn btn-sm btn-outline-info" onclick="showSessionDetails('${session.session_id}')">
                    상세보기
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// 세션 상세 정보 표시
async function showSessionDetails(sessionId) {
    try {
        const response = await fetch(`/api/sessions/${sessionId}/events/`);
        const events = await response.json();
        
        const modalBody = document.getElementById('session-details');
        modalBody.innerHTML = `
            <div class="row">
                <div class="col-md-6">
                    <h6>세션 정보</h6>
                    <p><strong>세션 ID:</strong> ${sessionId}</p>
                    <p><strong>이벤트 수:</strong> ${events.length}</p>
                </div>
                <div class="col-md-6">
                    <h6>최근 활동</h6>
                    <div class="timeline">
                        ${events.slice(-5).map(event => `
                            <div class="timeline-item">
                                <small class="text-muted">${formatTimestamp(event.timestamp)}</small><br>
                                <strong>${event.event_type}</strong>: ${event.page_url}
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;
        
        new bootstrap.Modal(document.getElementById('sessionModal')).show();
    } catch (error) {
        console.error('Error loading session details:', error);
    }
}

// 유틸리티 함수들
function formatTimestamp(timestamp) {
    return new Date(parseInt(timestamp)).toLocaleString('ko-KR');
}

function formatDuration(duration) {
    const minutes = Math.floor(duration / 60000);
    const seconds = Math.floor((duration % 60000) / 1000);
    return `${minutes}분 ${seconds}초`;
}

function truncateUrl(url) {
    return url.length > 50 ? url.substring(0, 50) + '...' : url;
}

function updateActiveCount(count) {
    document.getElementById('active-count').textContent = count;
}

function refreshSessions() {
    loadActiveSessions();
}

function startAutoRefresh() {
    refreshInterval = setInterval(loadActiveSessions, 10000); // 10초마다 새로고침
}

function showError(message) {
    // 에러 토스트 표시
    const toast = document.createElement('div');
    toast.className = 'toast align-items-center text-white bg-danger border-0';
    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">${message}</div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
    `;
    document.body.appendChild(toast);
    new bootstrap.Toast(toast).show();
}
</script>
{% endblock %}
```

### 2. 통계 차트 구현 (90분)

**dashboard/templates/dashboard/statistics.html**
```html
{% extends 'base.html' %}

{% block content %}
<div class="row mb-4">
    <div class="col-12">
        <h2>통계 대시보드</h2>
        <div class="row">
            <div class="col-md-3">
                <div class="card text-center">
                    <div class="card-body">
                        <h5 class="card-title">총 세션</h5>
                        <h3 class="text-primary" id="total-sessions">-</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-center">
                    <div class="card-body">
                        <h5 class="card-title">총 이벤트</h5>
                        <h3 class="text-success" id="total-events">-</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-center">
                    <div class="card-body">
                        <h5 class="card-title">평균 세션 시간</h5>
                        <h3 class="text-info" id="avg-session-time">-</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-center">
                    <div class="card-body">
                        <h5 class="card-title">전환율</h5>
                        <h3 class="text-warning" id="conversion-rate">-</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h5>시간대별 유입 통계</h5>
                <div class="btn-group btn-group-sm" role="group">
                    <button type="button" class="btn btn-outline-primary active" onclick="loadHourlyChart(24)">24시간</button>
                    <button type="button" class="btn btn-outline-primary" onclick="loadHourlyChart(168)">7일</button>
                    <button type="button" class="btn btn-outline-primary" onclick="loadHourlyChart(720)">30일</button>
                </div>
            </div>
            <div class="card-body">
                <canvas id="hourlyChart" height="100"></canvas>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <h5>페이지별 조회수</h5>
            </div>
            <div class="card-body">
                <canvas id="pageChart"></canvas>
            </div>
        </div>
    </div>
</div>

<div class="row mt-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <h5>유입 경로 분석</h5>
            </div>
            <div class="card-body">
                <canvas id="referrerChart" height="50"></canvas>
            </div>
        </div>
    </div>
</div>

<script>
let hourlyChart, pageChart, referrerChart;

document.addEventListener('DOMContentLoaded', function() {
    initializeCharts();
    loadStatistics();
});

function initializeCharts() {
    // 시간대별 차트
    const hourlyCtx = document.getElementById('hourlyChart').getContext('2d');
    hourlyChart = new Chart(hourlyCtx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: '세션 수',
                data: [],
                borderColor: 'rgb(75, 192, 192)',
                backgroundColor: 'rgba(75, 192, 192, 0.2)',
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });

    // 페이지별 차트
    const pageCtx = document.getElementById('pageChart').getContext('2d');
    pageChart = new Chart(pageCtx, {
        type: 'doughnut',
        data: {
            labels: [],
            datasets: [{
                data: [],
                backgroundColor: [
                    '#FF6384',
                    '#36A2EB',
                    '#FFCE56',
                    '#4BC0C0',
                    '#9966FF'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false
        }
    });

    // 유입 경로 차트
    const referrerCtx = document.getElementById('referrerChart').getContext('2d');
    referrerChart = new Chart(referrerCtx, {
        type: 'bar',
        data: {
            labels: [],
            datasets: [{
                label: '유입 수',
                data: [],
                backgroundColor: 'rgba(54, 162, 235, 0.5)',
                borderColor: 'rgba(54, 162, 235, 1)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
}

async function loadStatistics() {
    try {
        // 기본 통계 로드
        await loadSummaryStats();
        
        // 차트 데이터 로드
        await loadHourlyChart(24);
        await loadPageChart();
        await loadReferrerChart();
        
    } catch (error) {
        console.error('Error loading statistics:', error);
    }
}

async function loadSummaryStats() {
    // TODO: 실제 API 연동
    document.getElementById('total-sessions').textContent = '1,234';
    document.getElementById('total-events').textContent = '5,678';
    document.getElementById('avg-session-time').textContent = '3분 45초';
    document.getElementById('conversion-rate').textContent = '2.3%';
}

async function loadHourlyChart(hours) {
    try {
        const response = await fetch(`/api/statistics/hourly/?hours=${hours}`);
        const data = await response.json();
        
        hourlyChart.data.labels = data.map(item => item.hour);
        hourlyChart.data.datasets[0].data = data.map(item => item.count);
        hourlyChart.update();
        
        // 버튼 활성화 상태 업데이트
        document.querySelectorAll('.btn-group button').forEach(btn => btn.classList.remove('active'));
        event.target.classList.add('active');
        
    } catch (error) {
        console.error('Error loading hourly chart:', error);
    }
}

async function loadPageChart() {
    try {
        const response = await fetch('/api/statistics/pages/');
        const data = await response.json();
        
        pageChart.data.labels = data.map(item => item.page);
        pageChart.data.datasets[0].data = data.map(item => item.views);
        pageChart.update();
        
    } catch (error) {
        console.error('Error loading page chart:', error);
    }
}

async function loadReferrerChart() {
    // TODO: 유입 경로 데이터 로드
    referrerChart.data.labels = ['Google', 'Direct', 'Facebook', 'Twitter'];
    referrerChart.data.datasets[0].data = [45, 30, 15, 10];
    referrerChart.update();
}
</script>
{% endblock %}
```

### 3. API 연동 및 데이터 바인딩 (60분)

**dashboard/views.py 완성**
```python
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
```

**URL 설정 업데이트**
```python
# dashboard/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('statistics/', views.statistics, name='statistics'),
    path('api/sessions/active/', views.api_active_sessions, name='api_active_sessions'),
    path('api/sessions/<str:session_id>/events/', views.api_session_events, name='api_session_events'),
    path('api/statistics/hourly/', views.api_hourly_stats, name='api_hourly_stats'),
    path('api/statistics/pages/', views.api_page_stats, name='api_page_stats'),
]
```

## 완료 기준
- [ ] 실시간 세션 목록 화면 완성
- [ ] 세션 상세 모달 구현
- [ ] 시간대별/페이지별/유입경로별 차트 구현
- [ ] 모든 API 엔드포인트 연동 완료
- [ ] 반응형 UI 구성 완료
- [ ] 자동 새로고침 기능 구현