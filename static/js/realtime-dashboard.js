/**
 * 실시간 대시보드 전용 JavaScript
 */

class RealtimeDashboard {
    constructor() {
        this.autoRefresh = true;
        this.refreshInterval = null;
        this.charts = {};
        this.data = {
            sessions: [],
            events: [],
            stats: {}
        };
        
        this.init();
    }
    
    init() {
        this.initializeCharts();
        this.setupEventListeners();
        this.startDataPolling();
    }
    
    initializeCharts() {
        // 실시간 라인 차트
        this.charts.realtime = new Chart(document.getElementById('realtime-chart'), {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: '실시간 유입',
                    data: [],
                    borderColor: '#007bff',
                    backgroundColor: 'rgba(0, 123, 255, 0.1)',
                    tension: 0.4,
                    fill: true,
                    pointRadius: 4,
                    pointHoverRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    intersect: false,
                    mode: 'index'
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: { stepSize: 1 }
                    }
                },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        titleColor: '#fff',
                        bodyColor: '#fff',
                        borderColor: '#007bff',
                        borderWidth: 1,
                        callbacks: {
                            afterBody: (context) => {
                                const index = context[0].dataIndex;
                                const data = this.charts.realtime.data.datasets[0].data;
                                const cumulative = data.slice(0, index + 1).reduce((a, b) => a + b, 0);
                                return [`누적 유입: ${cumulative}명`];
                            }
                        }
                    }
                },
                onHover: (event, elements) => {
                    if (elements.length > 0) {
                        const index = elements[0].index;
                        const label = this.charts.realtime.data.labels[index];
                        const value = this.charts.realtime.data.datasets[0].data[index];
                        const cumulative = this.charts.realtime.data.datasets[0].data
                            .slice(0, index + 1).reduce((a, b) => a + b, 0);
                        
                        this.showCustomTooltip(event, {
                            title: label,
                            items: [
                                `실시간 유입: ${value}명`,
                                `누적 유입: ${cumulative}명`,
                                `시간대: ${label}`
                            ]
                        });
                    } else {
                        this.hideCustomTooltip();
                    }
                }
            }
        });
        
        // 페이지별 도넛 차트
        this.charts.pages = new Chart(document.getElementById('page-chart'), {
            type: 'doughnut',
            data: {
                labels: [],
                datasets: [{
                    data: [],
                    backgroundColor: [
                        '#FF6384', '#36A2EB', '#FFCE56', 
                        '#4BC0C0', '#9966FF', '#FF9F40'
                    ],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true
                        }
                    },
                    tooltip: {
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        callbacks: {
                            afterBody: (context) => {
                                const total = context[0].dataset.data.reduce((a, b) => a + b, 0);
                                const value = context[0].parsed;
                                const percentage = ((value / total) * 100).toFixed(1);
                                return [`비율: ${percentage}%`, `총 조회수: ${total}`];
                            }
                        }
                    }
                },
                onHover: (event, elements) => {
                    if (elements.length > 0) {
                        const index = elements[0].index;
                        const label = this.charts.pages.data.labels[index];
                        const value = this.charts.pages.data.datasets[0].data[index];
                        const total = this.charts.pages.data.datasets[0].data.reduce((a, b) => a + b, 0);
                        const percentage = ((value / total) * 100).toFixed(1);
                        
                        this.showCustomTooltip(event, {
                            title: label,
                            items: [
                                `조회수: ${value}회`,
                                `비율: ${percentage}%`,
                                `총 조회수: ${total}회`
                            ]
                        });
                    } else {
                        this.hideCustomTooltip();
                    }
                }
            }
        });
    }
    
    setupEventListeners() {
        // 자동 새로고침 토글
        window.toggleAutoRefresh = () => {
            this.autoRefresh = !this.autoRefresh;
            const icon = document.getElementById('refresh-icon');
            const text = document.getElementById('refresh-text');
            
            if (this.autoRefresh) {
                icon.className = 'fas fa-pause';
                text.textContent = '일시정지';
                this.startDataPolling();
            } else {
                icon.className = 'fas fa-play';
                text.textContent = '재시작';
                if (this.refreshInterval) {
                    clearInterval(this.refreshInterval);
                }
            }
        };
        
        // 세션 상세 보기
        window.showSessionDetails = async (sessionId) => {
            try {
                const response = await fetch(`/api/sessions/${sessionId}/events/`);
                const events = await response.json();
                
                const modalBody = document.getElementById('session-details');
                modalBody.innerHTML = this.renderSessionDetails(sessionId, events);
                
                new bootstrap.Modal(document.getElementById('sessionModal')).show();
            } catch (error) {
                console.error('Error loading session details:', error);
            }
        };
    }
    
    startDataPolling() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        
        // 즉시 로드
        this.loadAllData();
        
        // 5초마다 업데이트
        this.refreshInterval = setInterval(() => {
            if (this.autoRefresh) {
                this.loadAllData();
            }
        }, 5000);
    }
    
    async loadAllData() {
        try {
            const [sessions, summary, hourly, pages] = await Promise.all([
                fetch('/api/sessions/active/').then(r => r.json()),
                fetch('/api/statistics/summary/').then(r => r.json()),
                fetch('/api/statistics/hourly/').then(r => r.json()),
                fetch('/api/statistics/pages/').then(r => r.json())
            ]);
            
            this.updateSessions(sessions);
            this.updateSummaryStats(summary);
            this.updateRealtimeChart(hourly);
            this.updatePageChart(pages);
            this.updateLastUpdateTime();
            this.animateLiveIndicator();
            
        } catch (error) {
            console.error('Error loading data:', error);
        }
    }
    
    updateSessions(sessions) {
        this.data.sessions = sessions;
        
        const tbody = document.getElementById('sessions-tbody');
        tbody.innerHTML = sessions.map(session => `
            <tr>
                <td>${session.user_id}</td>
                <td><code>${session.session_id.substring(0, 12)}...</code></td>
                <td><a href="${session.current_page}" target="_blank">${this.truncateUrl(session.current_page)}</a></td>
                <td>${this.formatTimestamp(session.last_activity)}</td>
                <td>${this.formatDuration(session.duration)}</td>
                <td>
                    <button class="btn btn-sm btn-outline-info" onclick="showSessionDetails('${session.session_id}')">
                        상세보기
                    </button>
                </td>
            </tr>
        `).join('');
        
        document.getElementById('active-count').textContent = sessions.length;
    }
    
    updateSummaryStats(stats) {
        document.getElementById('total-sessions').textContent = stats.total_sessions || '0';
        document.getElementById('total-events').textContent = stats.total_events || '0';
        document.getElementById('avg-session-time').textContent = stats.avg_session_time || '0분';
        document.getElementById('conversion-rate').textContent = stats.conversion_rate || '0%';
    }
    
    updateRealtimeChart(hourlyData) {
        const maxPoints = 20;
        // 서버에서 받은 시간을 한국 시간대로 변환하여 표시
        const labels = hourlyData.map(item => {
            // 서버에서 HH:MM 형식으로 받은 시간을 현재 날짜와 결합
            const today = new Date();
            const [hours, minutes] = item.hour.split(':');
            const timeDate = new Date(today.getFullYear(), today.getMonth(), today.getDate(), parseInt(hours), parseInt(minutes));
            return timeDate.toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit', hour12: false });
        }).slice(-maxPoints);
        const data = hourlyData.map(item => item.count).slice(-maxPoints);
        
        this.charts.realtime.data.labels = labels;
        this.charts.realtime.data.datasets[0].data = data;
        this.charts.realtime.update('none');
    }
    
    updatePageChart(pageData) {
        const labels = pageData.map(item => item.page.replace('https://example.com', '') || '/');
        const data = pageData.map(item => item.views);
        
        this.charts.pages.data.labels = labels;
        this.charts.pages.data.datasets[0].data = data;
        this.charts.pages.update();
    }
    
    showCustomTooltip(event, data) {
        const tooltip = document.getElementById('chart-tooltip');
        const content = document.getElementById('tooltip-content');
        
        content.innerHTML = `
            <strong>${data.title}</strong><br>
            ${data.items.join('<br>')}
        `;
        
        tooltip.style.display = 'block';
        tooltip.style.left = (event.pageX + 10) + 'px';
        tooltip.style.top = (event.pageY - 10) + 'px';
    }
    
    hideCustomTooltip() {
        document.getElementById('chart-tooltip').style.display = 'none';
    }
    
    animateLiveIndicator() {
        const indicator = document.getElementById('live-indicator');
        indicator.style.opacity = '0.5';
        setTimeout(() => indicator.style.opacity = '1', 200);
    }
    
    updateLastUpdateTime() {
        document.getElementById('last-update').textContent = 
            new Date().toLocaleTimeString('ko-KR');
    }
    
    renderSessionDetails(sessionId, events) {
        return `
            <div class="row">
                <div class="col-md-6">
                    <h6>세션 정보</h6>
                    <p><strong>세션 ID:</strong> ${sessionId}</p>
                    <p><strong>이벤트 수:</strong> ${events.length}</p>
                    <p><strong>시작 시간:</strong> ${events.length > 0 ? this.formatTimestamp(events[0].timestamp) : 'N/A'}</p>
                </div>
                <div class="col-md-6">
                    <h6>최근 활동 (최대 5개)</h6>
                    <div class="timeline">
                        ${events.slice(-5).map(event => `
                            <div class="timeline-item mb-2 p-2 border-start border-3 border-primary">
                                <small class="text-muted">${this.formatTimestamp(event.timestamp)}</small><br>
                                <strong>${event.event_type}</strong><br>
                                <small>${event.page_url}</small>
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;
    }
    
    // 유틸리티 메서드들
    formatTimestamp(timestamp) {
        return new Date(parseInt(timestamp)).toLocaleString('ko-KR');
    }
    
    formatDuration(duration) {
        const minutes = Math.floor(duration / 60000);
        const seconds = Math.floor((duration % 60000) / 1000);
        return `${minutes}분 ${seconds}초`;
    }
    
    truncateUrl(url) {
        return url.length > 40 ? url.substring(0, 40) + '...' : url;
    }
}

// 페이지 로드 시 대시보드 초기화
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new RealtimeDashboard();
});