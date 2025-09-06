// 실시간 대시보드 JavaScript
let charts = {};
let autoRefresh = true;

// 차트 초기화
function initCharts() {
    // 실시간 차트
    const realtimeCtx = document.getElementById('realtime-chart').getContext('2d');
    charts.realtime = new Chart(realtimeCtx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: '이벤트 수',
                data: [],
                borderColor: '#3182f6',
                backgroundColor: 'rgba(49, 130, 246, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: { beginAtZero: true }
            }
        }
    });

    // 페이지 차트
    const pageCtx = document.getElementById('page-chart').getContext('2d');
    charts.page = new Chart(pageCtx, {
        type: 'bar',
        data: {
            labels: [],
            datasets: [{
                label: '조회수',
                data: [],
                backgroundColor: '#00c73c'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            }
        }
    });
}

// 데이터 업데이트
async function updateData() {
    try {
        // 요약 통계
        const summaryRes = await fetch('/api/statistics/summary/');
        const summary = await summaryRes.json();
        
        document.getElementById('total-sessions').textContent = summary.total_sessions || '0';
        document.getElementById('total-events').textContent = summary.total_events || '0';
        document.getElementById('avg-session-time').textContent = summary.avg_session_time || '0분';
        document.getElementById('conversion-rate').textContent = summary.conversion_rate || '0%';

        // 시간대별 데이터
        const hourlyRes = await fetch('/api/statistics/hourly/');
        const hourlyData = await hourlyRes.json();
        
        charts.realtime.data.labels = hourlyData.map(d => d.hour);
        charts.realtime.data.datasets[0].data = hourlyData.map(d => d.count);
        charts.realtime.update();

        // 페이지별 데이터
        const pagesRes = await fetch('/api/statistics/pages/');
        const pagesData = await pagesRes.json();
        
        const topPages = pagesData.slice(0, 5);
        charts.page.data.labels = topPages.map(p => p.page);
        charts.page.data.datasets[0].data = topPages.map(p => p.views);
        charts.page.update();

        // 활성 세션
        const sessionsRes = await fetch('/api/sessions/active/');
        const sessions = await sessionsRes.json();
        
        const tbody = document.getElementById('sessions-tbody');
        if (sessions.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center py-4 text-muted">활성 세션이 없습니다</td></tr>';
        } else {
            tbody.innerHTML = sessions.map(session => `
                <tr>
                    <td><code>${session.user_id.substring(0, 12)}...</code></td>
                    <td><code>${session.session_id.substring(0, 20)}...</code></td>
                    <td>${session.current_page || '-'}</td>
                    <td>${new Date(session.last_activity).toLocaleTimeString()}</td>
                    <td>${Math.floor(session.duration / 60000)}분</td>
                </tr>
            `).join('');
        }

    } catch (error) {
        console.error('데이터 업데이트 실패:', error);
    }
}

// 초기화
document.addEventListener('DOMContentLoaded', function() {
    initCharts();
    updateData();
    
    // 30초마다 자동 업데이트
    setInterval(() => {
        if (autoRefresh) {
            updateData();
        }
    }, 30000);
});