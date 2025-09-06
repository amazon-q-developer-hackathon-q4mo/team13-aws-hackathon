/**
 * Toss 스타일 실시간 대시보드
 */

class TossDashboard {
    constructor() {
        this.autoRefresh = true;
        this.refreshInterval = null;
        this.charts = {};
        this.data = {
            sessions: [],
            stats: {},
            isLoading: false
        };
        this.isModalOpen = false;
        this.updateCounter = 0;
        this.sortConfig = {
            field: null,
            direction: 'asc'
        };
        
        this.init();
    }
    
    init() {
        this.initializeCharts();
        this.setupEventListeners();
        this.initializeTooltips();
        this.startDataPolling();
        this.showWelcomeAnimation();
    }
    
    initializeTooltips() {
        // Bootstrap 툴팁 초기화
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    }
    
    showWelcomeAnimation() {
        // 페이지 로드 시 부드러운 애니메이션
        setTimeout(() => {
            document.querySelectorAll('.fade-in, .slide-up').forEach((el, index) => {
                el.style.animationDelay = `${index * 0.1}s`;
                el.classList.add('animate');
            });
        }, 100);
    }
    
    initializeCharts() {
        // Toss 스타일 차트 설정
        Chart.defaults.font.family = 'Pretendard, -apple-system, BlinkMacSystemFont, system-ui, sans-serif';
        Chart.defaults.font.size = 12;
        Chart.defaults.color = '#8b95a1';
        
        // 실시간 라인 차트
        this.charts.realtime = new Chart(document.getElementById('realtime-chart'), {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: '실시간 유입',
                    data: [],
                    borderColor: '#3182f6',
                    backgroundColor: 'rgba(49, 130, 246, 0.1)',
                    tension: 0.4,
                    fill: true,
                    pointRadius: 0,
                    pointHoverRadius: 6,
                    pointHoverBackgroundColor: '#3182f6',
                    pointHoverBorderColor: '#ffffff',
                    pointHoverBorderWidth: 2,
                    borderWidth: 3
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
                    x: {
                        grid: {
                            display: false
                        },
                        border: {
                            display: false
                        },
                        ticks: {
                            maxTicksLimit: 8,
                            color: '#8b95a1'
                        }
                    },
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: '#f2f4f6',
                            borderDash: [2, 2]
                        },
                        border: {
                            display: false
                        },
                        ticks: {
                            stepSize: 1,
                            color: '#8b95a1',
                            callback: function(value) {
                                return value + '명';
                            }
                        }
                    }
                },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        enabled: false,
                        external: (context) => this.showCustomTooltip(context)
                    }
                },
                elements: {
                    point: {
                        hoverRadius: 8
                    }
                },
                animation: {
                    duration: 750,
                    easing: 'easeInOutQuart'
                },
                onClick: (event, elements) => {
                    if (elements.length > 0) {
                        const dataIndex = elements[0].index;
                        const hour = this.charts.realtime.data.labels[dataIndex];
                        this.showHourlyDetails(hour);
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
                        '#3182f6', '#00c73c', '#ff6b35', 
                        '#f04452', '#8b5cf6', '#06b6d4'
                    ],
                    borderWidth: 0,
                    hoverBorderWidth: 2,
                    hoverBorderColor: '#ffffff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true,
                            pointStyle: 'circle',
                            font: {
                                size: 11,
                                weight: '500'
                            },
                            color: '#191f28'
                        }
                    },
                    tooltip: {
                        enabled: false,
                        external: (context) => this.showCustomTooltip(context)
                    }
                },
                animation: {
                    animateRotate: true,
                    duration: 1000
                },
                onClick: (event, elements) => {
                    if (elements.length > 0) {
                        const dataIndex = elements[0].index;
                        const pageLabel = this.charts.pages.data.labels[dataIndex];
                        const fullPageUrl = `https://example.com${pageLabel}`;
                        this.showPageDetails(fullPageUrl);
                    }
                }
            }
        });
        
        // 유입경로 바 차트
        this.charts.referrers = new Chart(document.getElementById('referrer-chart'), {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: '방문자 수',
                    data: [],
                    backgroundColor: '#3182f6',
                    borderRadius: 6,
                    borderSkipped: false
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                indexAxis: 'y',
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        enabled: false,
                        external: (context) => this.showCustomTooltip(context)
                    }
                },
                scales: {
                    x: {
                        beginAtZero: true,
                        grid: {
                            color: '#f2f4f6'
                        },
                        ticks: {
                            color: '#8b95a1'
                        }
                    },
                    y: {
                        grid: {
                            display: false
                        },
                        ticks: {
                            color: '#8b95a1',
                            font: {
                                size: 11
                            }
                        }
                    }
                },
                animation: {
                    duration: 800
                },
                onClick: (event, elements) => {
                    if (elements.length > 0) {
                        const dataIndex = elements[0].index;
                        const referrer = this.charts.referrers.data.labels[dataIndex];
                        this.showReferrerDetails(referrer);
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
            const updateStatus = document.getElementById('update-status');
            
            if (this.autoRefresh) {
                icon.className = 'fas fa-pause';
                text.textContent = '일시정지';
                updateStatus.classList.remove('paused');
                updateStatus.querySelector('span').textContent = '실시간 업데이트';
                this.startDataPolling();
                this.showToast('자동 새로고침이 시작되었습니다.');
            } else {
                icon.className = 'fas fa-play';
                text.textContent = '재시작';
                updateStatus.classList.add('paused');
                updateStatus.querySelector('span').textContent = '업데이트 일시정지';
                if (this.refreshInterval) {
                    clearInterval(this.refreshInterval);
                }
                this.showToast('자동 새로고침이 일시정지되었습니다.');
            }
        };
        
        // 세션 상세 보기
        window.showSessionDetails = async (sessionId) => {
            try {
                this.isModalOpen = true;
                this.showModalLoading();
                const response = await fetch(`/api/sessions/${sessionId}/events/`);
                const events = await response.json();
                
                const modalBody = document.getElementById('session-details');
                modalBody.innerHTML = this.renderSessionDetails(sessionId, events);
                
                // 기존 모달 인스턴스 정리
                const existingModal = bootstrap.Modal.getInstance(document.getElementById('sessionModal'));
                if (existingModal) {
                    existingModal.dispose();
                }
                
                const modal = new bootstrap.Modal(document.getElementById('sessionModal'));
                modal.show();
            } catch (error) {
                console.error('Error loading session details:', error);
                this.showToast('세션 정보를 불러오는데 실패했습니다.', 'error');
                this.isModalOpen = false;
            }
        };
        
        // 테이블 정렬 및 행 클릭 이벤트
        document.addEventListener('click', (e) => {
            // 정렬 헤더 클릭
            const sortHeader = e.target.closest('.sortable');
            if (sortHeader) {
                const field = sortHeader.dataset.sort;
                this.sortTable(field);
                return;
            }
            
            // 테이블 행 클릭
            const row = e.target.closest('tbody tr');
            if (row && row.dataset.sessionId && !e.target.closest('button')) {
                const sessionId = row.dataset.sessionId;
                showSessionDetails(sessionId);
            }
        });
        
        // 모달 닫힐 때 그림자 효과 제거
        const modal = document.getElementById('sessionModal');
        if (modal) {
            modal.addEventListener('shown.bs.modal', () => {
                this.isModalOpen = true;
                this.updateModalStatus(true);
            });
            
            modal.addEventListener('hidden.bs.modal', () => {
                this.isModalOpen = false;
                this.updateModalStatus(false);
                
                // 모든 backdrop 제거
                const backdrops = document.querySelectorAll('.modal-backdrop');
                backdrops.forEach(backdrop => backdrop.remove());
                
                // body 클래스 정리
                document.body.classList.remove('modal-open');
                document.body.style.overflow = '';
                document.body.style.paddingRight = '';
            });
        }
    }
    
    startDataPolling() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        
        // 즉시 로드
        this.loadAllData();
        
        // 10초마다 업데이트 (모달이 열려있지 않을 때만)
        this.refreshInterval = setInterval(() => {
            if (this.autoRefresh && !this.isModalOpen) {
                this.loadAllData();
            }
        }, 10000);
    }
    
    async loadAllData() {
        if (this.data.isLoading) return;
        
        this.data.isLoading = true;
        this.showChartLoading(true);
        
        try {
            const [sessions, summary, hourly, pages, referrers] = await Promise.all([
                fetch('/api/sessions/active/').then(r => r.json()),
                fetch('/api/statistics/summary/').then(r => r.json()),
                fetch('/api/statistics/hourly/').then(r => r.json()),
                fetch('/api/statistics/pages/').then(r => r.json()),
                fetch('/api/statistics/referrers/').then(r => r.json())
            ]);
            
            this.updateSessions(sessions);
            this.updateSummaryStats(summary);
            this.updateRealtimeChart(hourly);
            this.updatePageChart(pages);
            this.updateReferrerChart(referrers);
            this.updateLastUpdateTime();
            this.animateLiveIndicator();
            
            // 데이터 업데이트 토스트 (첫 로드가 아닐 때만)
            if (this.data.sessions.length > 0) {
                this.showUpdateToast();
            }
            
        } catch (error) {
            console.error('Error loading data:', error);
            this.showToast('데이터를 불러오는데 실패했습니다.', 'error');
        } finally {
            this.data.isLoading = false;
            this.showChartLoading(false);
        }
    }
    
    updateSessions(sessions) {
        // 스마트 업데이트: 데이터가 실제로 변경되었을 때만 DOM 업데이트
        const currentSessionIds = this.data.sessions.map(s => s.session_id).sort();
        const newSessionIds = sessions.map(s => s.session_id).sort();
        
        const hasChanged = JSON.stringify(currentSessionIds) !== JSON.stringify(newSessionIds) ||
                          this.data.sessions.length !== sessions.length;
        
        this.data.sessions = sessions;
        
        if (!hasChanged && this.updateCounter > 0) {
            // 세션 목록이 변경되지 않았으면 시간 정보만 업데이트
            this.updateSessionTimes(sessions);
            return;
        }
        
        this.updateCounter++;
        this.renderSessionTable();
        document.getElementById('active-count').textContent = sessions.length;
    }
    
    renderSessionTable() {
        const tbody = document.getElementById('sessions-tbody');
        let sessionsToRender = [...this.data.sessions];
        
        // 정렬 적용
        if (this.sortConfig.field) {
            sessionsToRender = this.sortSessions(sessionsToRender);
        }
        
        if (sessionsToRender.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center py-5 text-muted">
                        <i class="fas fa-users fa-3x mb-3 d-block"></i>
                        현재 활성 세션이 없습니다
                    </td>
                </tr>
            `;
        } else {
            tbody.style.opacity = '0.7';
            
            setTimeout(() => {
                tbody.innerHTML = sessionsToRender.map((session, index) => `
                    <tr data-session-id="${session.session_id}" style="cursor: pointer;" class="table-row-clickable session-row">
                        <td>
                            <div class="d-flex align-items-center">
                                <div class="bg-primary rounded-circle d-flex align-items-center justify-content-center me-2" 
                                     style="width: 32px; height: 32px; font-size: 0.8rem; color: white;">
                                    ${session.user_id.charAt(session.user_id.length - 1).toUpperCase()}
                                </div>
                                <span class="fw-medium">${session.user_id}</span>
                            </div>
                        </td>
                        <td><code>${session.session_id.substring(0, 12)}...</code></td>
                        <td>
                            <a href="${session.current_page}" target="_blank" class="text-decoration-none">
                                ${this.truncateUrl(session.current_page)}
                            </a>
                        </td>
                        <td class="last-activity">
                            <small class="text-muted">${this.formatTimestamp(session.last_activity)}</small>
                        </td>
                        <td class="duration">
                            <span class="badge bg-light text-dark">${this.formatDuration(session.duration)}</span>
                        </td>
                        <td>
                            <button class="btn btn-outline-primary btn-sm" onclick="showSessionDetails('${session.session_id}')">
                                <i class="fas fa-eye me-1"></i>상세보기
                            </button>
                        </td>
                    </tr>
                `).join('');
                
                tbody.style.opacity = '1';
            }, 150);
        }
    }
    
    updateSessionTimes(sessions) {
        sessions.forEach(session => {
            const row = document.querySelector(`tr[data-session-id="${session.session_id}"]`);
            if (row) {
                const lastActivityCell = row.querySelector('.last-activity small');
                const durationCell = row.querySelector('.duration .badge');
                
                if (lastActivityCell) {
                    lastActivityCell.textContent = this.formatTimestamp(session.last_activity);
                }
                if (durationCell) {
                    durationCell.textContent = this.formatDuration(session.duration);
                }
            }
        });
    }
    
    sortTable(field) {
        if (this.sortConfig.field === field) {
            this.sortConfig.direction = this.sortConfig.direction === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortConfig.field = field;
            this.sortConfig.direction = 'asc';
        }
        
        this.updateSortHeaders();
        this.renderSessionTable();
    }
    
    sortSessions(sessions) {
        const { field, direction } = this.sortConfig;
        
        return sessions.sort((a, b) => {
            let aVal, bVal;
            
            switch (field) {
                case 'user_id':
                    aVal = a.user_id.toLowerCase();
                    bVal = b.user_id.toLowerCase();
                    break;
                case 'session_id':
                    aVal = a.session_id;
                    bVal = b.session_id;
                    break;
                case 'current_page':
                    aVal = a.current_page.toLowerCase();
                    bVal = b.current_page.toLowerCase();
                    break;
                case 'last_activity':
                    aVal = parseInt(a.last_activity);
                    bVal = parseInt(b.last_activity);
                    break;
                case 'duration':
                    aVal = parseInt(a.duration);
                    bVal = parseInt(b.duration);
                    break;
                default:
                    return 0;
            }
            
            if (aVal < bVal) return direction === 'asc' ? -1 : 1;
            if (aVal > bVal) return direction === 'asc' ? 1 : -1;
            return 0;
        });
    }
    
    updateSortHeaders() {
        document.querySelectorAll('.sortable').forEach(header => {
            const icon = header.querySelector('.sort-icon');
            if (icon) {
                icon.className = 'fas fa-sort sort-icon ms-1 text-muted';
            }
        });
        
        if (this.sortConfig.field) {
            const activeHeader = document.querySelector(`[data-sort="${this.sortConfig.field}"]`);
            if (activeHeader) {
                const icon = activeHeader.querySelector('.sort-icon');
                if (icon) {
                    icon.className = `fas fa-sort-${this.sortConfig.direction === 'asc' ? 'up' : 'down'} sort-icon ms-1 text-primary`;
                }
            }
        }
    }
    
    updateSummaryStats(stats) {
        this.animateNumber('total-sessions', stats.total_sessions || '0');
        this.animateNumber('total-events', stats.total_events || '0');
        document.getElementById('avg-session-time').textContent = stats.avg_session_time || '0분';
        document.getElementById('conversion-rate').textContent = stats.conversion_rate || '0%';
    }
    
    updateRealtimeChart(hourlyData) {
        // 최근 24시간 데이터 사용 (현재 시간 포함)
        const labels = hourlyData.map(item => item.hour);
        const data = hourlyData.map(item => item.count);
        
        // 데이터가 있을 때만 업데이트
        if (labels.length > 0) {
            this.charts.realtime.data.labels = labels;
            this.charts.realtime.data.datasets[0].data = data;
            this.charts.realtime.update('none'); // 부드러운 업데이트
            
            // 최대값 계산하여 Y축 조정
            const maxValue = Math.max(...data);
            if (maxValue > 0) {
                this.charts.realtime.options.scales.y.max = Math.ceil(maxValue * 1.2);
            }
        }
    }
    
    updatePageChart(pageData) {
        const labels = pageData.map(item => {
            const path = item.page.replace('https://example.com', '') || '/';
            return path.length > 15 ? path.substring(0, 15) + '...' : path;
        });
        const data = pageData.map(item => item.views);
        
        this.charts.pages.data.labels = labels;
        this.charts.pages.data.datasets[0].data = data;
        this.charts.pages.update('active');
    }
    
    updateReferrerChart(referrerData) {
        const labels = referrerData.map(item => {
            if (!item.referrer || item.referrer === 'direct') {
                return '직접 접속';
            }
            const domain = item.referrer.replace(/^https?:\/\//, '').split('/')[0];
            return domain.length > 20 ? domain.substring(0, 20) + '...' : domain;
        });
        const data = referrerData.map(item => item.count);
        
        this.charts.referrers.data.labels = labels;
        this.charts.referrers.data.datasets[0].data = data;
        this.charts.referrers.update('active');
    }
    
    showCustomTooltip(context) {
        const tooltip = document.getElementById('chart-tooltip');
        const tooltipModel = context.tooltip;
        
        if (tooltipModel.opacity === 0) {
            tooltip.style.display = 'none';
            return;
        }
        
        // 툴팁 내용 생성
        let content = '';
        if (context.chart.config.type === 'line') {
            const dataIndex = tooltipModel.dataPoints[0].dataIndex;
            const label = tooltipModel.dataPoints[0].label;
            const value = tooltipModel.dataPoints[0].parsed.y;
            const cumulative = this.charts.realtime.data.datasets[0].data
                .slice(0, dataIndex + 1).reduce((a, b) => a + b, 0);
            
            content = `
                <div class="fw-bold mb-1">${label}</div>
                <div class="d-flex justify-content-between">
                    <span>실시간 유입:</span>
                    <span class="fw-bold text-primary">${value}명</span>
                </div>
                <div class="d-flex justify-content-between">
                    <span>누적 유입:</span>
                    <span class="fw-bold">${cumulative}명</span>
                </div>
            `;
        } else if (context.chart.config.type === 'doughnut') {
            const dataIndex = tooltipModel.dataPoints[0].dataIndex;
            const label = tooltipModel.dataPoints[0].label;
            const value = tooltipModel.dataPoints[0].parsed;
            const total = this.charts.pages.data.datasets[0].data.reduce((a, b) => a + b, 0);
            const percentage = ((value / total) * 100).toFixed(1);
            
            content = `
                <div class="fw-bold mb-1">${label}</div>
                <div class="d-flex justify-content-between">
                    <span>조회수:</span>
                    <span class="fw-bold text-primary">${value}회</span>
                </div>
                <div class="d-flex justify-content-between">
                    <span>비율:</span>
                    <span class="fw-bold">${percentage}%</span>
                </div>
            `;
        } else if (context.chart.config.type === 'bar') {
            const dataIndex = tooltipModel.dataPoints[0].dataIndex;
            const label = tooltipModel.dataPoints[0].label;
            const value = tooltipModel.dataPoints[0].parsed.x;
            const total = this.charts.referrers.data.datasets[0].data.reduce((a, b) => a + b, 0);
            const percentage = ((value / total) * 100).toFixed(1);
            
            content = `
                <div class="fw-bold mb-1">${label}</div>
                <div class="d-flex justify-content-between">
                    <span>방문자:</span>
                    <span class="fw-bold text-primary">${value}명</span>
                </div>
                <div class="d-flex justify-content-between">
                    <span>비율:</span>
                    <span class="fw-bold">${percentage}%</span>
                </div>
            `;
        }
        
        document.getElementById('tooltip-content').innerHTML = content;
        
        // 툴팁 위치 설정
        const canvas = context.chart.canvas;
        const canvasRect = canvas.getBoundingClientRect();
        
        tooltip.style.display = 'block';
        tooltip.style.left = canvasRect.left + tooltipModel.caretX + 'px';
        tooltip.style.top = canvasRect.top + tooltipModel.caretY - tooltip.offsetHeight - 10 + 'px';
    }
    
    animateNumber(elementId, targetValue) {
        const element = document.getElementById(elementId);
        const currentValue = parseInt(element.textContent) || 0;
        const target = parseInt(targetValue) || 0;
        
        if (currentValue === target) return;
        
        const duration = 1000;
        const steps = 30;
        const stepValue = (target - currentValue) / steps;
        let current = currentValue;
        
        const timer = setInterval(() => {
            current += stepValue;
            if ((stepValue > 0 && current >= target) || (stepValue < 0 && current <= target)) {
                element.textContent = target.toLocaleString();
                clearInterval(timer);
            } else {
                element.textContent = Math.round(current).toLocaleString();
            }
        }, duration / steps);
    }
    
    showChartLoading(show) {
        const loading = document.getElementById('chart-loading');
        if (loading) {
            loading.style.display = show ? 'block' : 'none';
        }
    }
    
    showModalLoading() {
        const modalBody = document.getElementById('session-details');
        modalBody.innerHTML = `
            <div class="text-center py-4">
                <div class="loading me-2"></div>
                세션 정보를 불러오는 중...
            </div>
        `;
    }
    
    animateLiveIndicator() {
        const indicator = document.querySelector('.live-badge');
        indicator.style.transform = 'scale(1.1)';
        setTimeout(() => {
            indicator.style.transform = 'scale(1)';
        }, 200);
    }
    
    updateLastUpdateTime() {
        const now = new Date();
        document.getElementById('last-update').textContent = 
            '마지막 업데이트: ' + now.toLocaleTimeString([], {
                hour12: false,
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
    }
    
    showToast(message, type = 'info') {
        const toast = document.getElementById('update-toast');
        const toastBody = toast.querySelector('.toast-body');
        
        toastBody.textContent = message;
        
        if (type === 'error') {
            toast.querySelector('.toast-header i').className = 'fas fa-exclamation-triangle text-danger me-2';
        } else {
            toast.querySelector('.toast-header i').className = 'fas fa-sync-alt text-primary me-2';
        }
        
        new bootstrap.Toast(toast).show();
    }
    
    showUpdateToast() {
        // 조용한 업데이트 알림 (너무 자주 뜨지 않도록)
        if (!this.lastToastTime || Date.now() - this.lastToastTime > 30000) {
            this.lastToastTime = Date.now();
            // 토스트 대신 라이브 인디케이터만 애니메이션
        }
    }
    
    updateModalStatus(isOpen) {
        const updateStatus = document.getElementById('update-status');
        const tableContainer = document.querySelector('.sessions-table-container');
        
        if (isOpen) {
            updateStatus.classList.add('paused');
            updateStatus.querySelector('span').textContent = '상세보기 중 (업데이트 일시정지)';
            tableContainer.classList.add('update-paused');
        } else {
            if (this.autoRefresh) {
                updateStatus.classList.remove('paused');
                updateStatus.querySelector('span').textContent = '실시간 업데이트';
            }
            tableContainer.classList.remove('update-paused');
        }
    }
    
    renderSessionDetails(sessionId, events) {
        const startTime = events.length > 0 ? events[0].timestamp : null;
        const endTime = events.length > 0 ? events[events.length - 1].timestamp : null;
        const duration = startTime && endTime ? endTime - startTime : 0;
        
        return `
            <div class="row g-4">
                <div class="col-md-6">
                    <div class="card border-0 bg-light">
                        <div class="card-body">
                            <h6 class="card-title mb-3">
                                <i class="fas fa-info-circle text-primary me-2"></i>
                                세션 정보
                            </h6>
                            <div class="mb-2">
                                <small class="text-muted">세션 ID</small>
                                <div class="fw-medium">${sessionId}</div>
                            </div>
                            <div class="mb-2">
                                <small class="text-muted">총 이벤트</small>
                                <div class="fw-medium">${events.length}개</div>
                            </div>
                            <div class="mb-2">
                                <small class="text-muted">세션 시간</small>
                                <div class="fw-medium">${this.formatDuration(duration)}</div>
                            </div>
                            ${startTime ? `
                            <div class="mb-0">
                                <small class="text-muted">시작 시간</small>
                                <div class="fw-medium">${this.formatTimestamp(startTime)}</div>
                            </div>
                            ` : ''}
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <h6 class="mb-3">
                        <i class="fas fa-history text-primary me-2"></i>
                        최근 활동 기록
                    </h6>
                    <div class="timeline-container" style="max-height: 300px; overflow-y: auto;">
                        ${events.slice(-10).reverse().map((event, index) => `
                            <div class="timeline-item" style="animation-delay: ${index * 0.1}s">
                                <div class="d-flex justify-content-between align-items-start mb-1">
                                    <span class="badge bg-primary">${event.event_type}</span>
                                    <small class="text-muted">${this.formatTimestamp(event.timestamp)}</small>
                                </div>
                                <div class="small text-truncate">${event.page_url}</div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;
    }
    
    // 유틸리티 메서드들
    formatTimestamp(timestamp) {
        const date = new Date(parseInt(timestamp));
        return date.toLocaleString([], {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        });
    }
    
    formatDuration(duration) {
        const minutes = Math.floor(duration / 60000);
        const seconds = Math.floor((duration % 60000) / 1000);
        
        if (minutes > 0) {
            return `${minutes}분 ${seconds}초`;
        } else {
            return `${seconds}초`;
        }
    }
    
    truncateUrl(url) {
        const path = url.replace('https://example.com', '') || '/';
        return path.length > 30 ? path.substring(0, 30) + '...' : path;
    }
    
    async showHourlyDetails(hour) {
        try {
            this.isModalOpen = true;
            const response = await fetch(`/api/hourly-details/?hour=${encodeURIComponent(hour)}`);
            const data = await response.json();
            
            const modalBody = document.getElementById('session-details');
            modalBody.innerHTML = `
                <div class="row g-4">
                    <div class="col-md-6">
                        <div class="card border-0 bg-light">
                            <div class="card-body">
                                <h6 class="card-title mb-3">
                                    <i class="fas fa-clock text-primary me-2"></i>
                                    ${hour} 시간대 상세
                                </h6>
                                <div class="mb-2">
                                    <small class="text-muted">총 이벤트</small>
                                    <div class="fw-bold text-primary">${data.total_events}개</div>
                                </div>
                                <div class="mb-2">
                                    <small class="text-muted">시간대</small>
                                    <div class="fw-medium">${data.hour}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <h6 class="mb-3">
                            <i class="fas fa-list text-primary me-2"></i>
                            최근 이벤트 (최대 20개)
                        </h6>
                        <div class="timeline-container" style="max-height: 300px; overflow-y: auto;">
                            ${data.events.map((event, index) => `
                                <div class="timeline-item" style="animation-delay: ${index * 0.05}s">
                                    <div class="d-flex justify-content-between align-items-start mb-1">
                                        <span class="badge bg-primary">${event.event_type}</span>
                                        <small class="text-muted">${event.formatted_time}</small>
                                    </div>
                                    <div class="small mb-1">
                                        <strong>사용자:</strong> ${event.user_id}
                                    </div>
                                    <div class="small text-truncate">${event.page_url}</div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
            `;
            
            document.querySelector('.modal-title').textContent = `${hour} 시간대 상세 정보`;
            
            // 기존 모달 인스턴스 정리
            const existingModal = bootstrap.Modal.getInstance(document.getElementById('sessionModal'));
            if (existingModal) {
                existingModal.dispose();
            }
            
            const modal = new bootstrap.Modal(document.getElementById('sessionModal'));
            modal.show();
            
        } catch (error) {
            console.error('Error loading hourly details:', error);
            this.showToast('시간대 상세 정보를 불러오는데 실패했습니다.', 'error');
            this.isModalOpen = false;
        }
    }
    
    async showPageDetails(pageUrl) {
        try {
            this.isModalOpen = true;
            const response = await fetch(`/api/page-details/?page=${encodeURIComponent(pageUrl)}`);
            const data = await response.json();
            
            const modalBody = document.getElementById('session-details');
            modalBody.innerHTML = `
                <div class="row g-4">
                    <div class="col-md-6">
                        <div class="card border-0 bg-light">
                            <div class="card-body">
                                <h6 class="card-title mb-3">
                                    <i class="fas fa-file-alt text-primary me-2"></i>
                                    페이지 상세 정보
                                </h6>
                                <div class="mb-2">
                                    <small class="text-muted">페이지 URL</small>
                                    <div class="fw-medium small">${data.page_url}</div>
                                </div>
                                <div class="mb-2">
                                    <small class="text-muted">총 조회수</small>
                                    <div class="fw-bold text-primary">${data.total_views}회</div>
                                </div>
                                <div class="mb-2">
                                    <small class="text-muted">시간대별 분포</small>
                                    <div class="mt-2">
                                        ${Object.entries(data.hourly_distribution).map(([hour, count]) => `
                                            <div class="d-flex justify-content-between">
                                                <span class="small">${hour}</span>
                                                <span class="badge bg-light text-dark">${count}회</span>
                                            </div>
                                        `).join('')}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <h6 class="mb-3">
                            <i class="fas fa-history text-primary me-2"></i>
                            최근 방문 기록 (10개)
                        </h6>
                        <div class="timeline-container" style="max-height: 300px; overflow-y: auto;">
                            ${data.recent_events.map((event, index) => `
                                <div class="timeline-item" style="animation-delay: ${index * 0.05}s">
                                    <div class="d-flex justify-content-between align-items-start mb-1">
                                        <span class="fw-medium">${event.user_id}</span>
                                        <small class="text-muted">${event.formatted_time}</small>
                                    </div>
                                    <div class="small text-muted">
                                        ${event.referrer ? `유입: ${event.referrer}` : '직접 접속'}
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
            `;
            
            const pageName = pageUrl.replace('https://example.com', '') || '/';
            document.querySelector('.modal-title').textContent = `${pageName} 페이지 상세 정보`;
            
            // 기존 모달 인스턴스 정리
            const existingModal = bootstrap.Modal.getInstance(document.getElementById('sessionModal'));
            if (existingModal) {
                existingModal.dispose();
            }
            
            const modal = new bootstrap.Modal(document.getElementById('sessionModal'));
            modal.show();
            
        } catch (error) {
            console.error('Error loading page details:', error);
            this.showToast('페이지 상세 정보를 불러오는데 실패했습니다.', 'error');
            this.isModalOpen = false;
        }
    }
    
    async showReferrerDetails(referrer) {
        try {
            this.isModalOpen = true;
            const response = await fetch(`/api/referrer-details/?referrer=${encodeURIComponent(referrer)}`);
            const data = await response.json();
            
            const modalBody = document.getElementById('session-details');
            modalBody.innerHTML = `
                <div class="row g-4">
                    <div class="col-md-6">
                        <div class="card border-0 bg-light">
                            <div class="card-body">
                                <h6 class="card-title mb-3">
                                    <i class="fas fa-external-link-alt text-primary me-2"></i>
                                    유입경로 상세
                                </h6>
                                <div class="mb-2">
                                    <small class="text-muted">유입경로</small>
                                    <div class="fw-medium">${referrer === '직접 접속' ? '직접 접속' : data.referrer}</div>
                                </div>
                                <div class="mb-2">
                                    <small class="text-muted">총 방문자</small>
                                    <div class="fw-bold text-primary">${data.total_visitors}명</div>
                                </div>
                                <div class="mb-2">
                                    <small class="text-muted">시간대별 분포</small>
                                    <div class="mt-2">
                                        ${Object.entries(data.hourly_distribution).map(([hour, count]) => `
                                            <div class="d-flex justify-content-between">
                                                <span class="small">${hour}</span>
                                                <span class="badge bg-light text-dark">${count}명</span>
                                            </div>
                                        `).join('')}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <h6 class="mb-3">
                            <i class="fas fa-history text-primary me-2"></i>
                            최근 유입 기록 (10개)
                        </h6>
                        <div class="timeline-container" style="max-height: 300px; overflow-y: auto;">
                            ${data.recent_visits.map((visit, index) => `
                                <div class="timeline-item" style="animation-delay: ${index * 0.05}s">
                                    <div class="d-flex justify-content-between align-items-start mb-1">
                                        <span class="fw-medium">${visit.user_id}</span>
                                        <small class="text-muted">${visit.formatted_time}</small>
                                    </div>
                                    <div class="small text-muted">
                                        랜딩 페이지: ${visit.landing_page}
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
            `;
            
            document.querySelector('.modal-title').textContent = `${referrer} 유입경로 상세`;
            
            const existingModal = bootstrap.Modal.getInstance(document.getElementById('sessionModal'));
            if (existingModal) {
                existingModal.dispose();
            }
            
            const modal = new bootstrap.Modal(document.getElementById('sessionModal'));
            modal.show();
            
        } catch (error) {
            console.error('Error loading referrer details:', error);
            this.showToast('유입경로 상세 정보를 불러오는데 실패했습니다.', 'error');
            this.isModalOpen = false;
        }
    }
}

// 페이지 로드 시 대시보드 초기화
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new TossDashboard();
});