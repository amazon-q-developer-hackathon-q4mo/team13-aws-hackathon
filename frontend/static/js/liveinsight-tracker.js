(function() {
    'use strict';
    
    // LiveInsight 추적 스크립트
    class LiveInsightTracker {
        constructor(config) {
            this.apiUrl = config.apiUrl || 'http://localhost:8000';
            this.apiKey = config.apiKey || 'dev-api-key-12345';
            this.sessionId = this.getOrCreateSessionId();
            this.userId = config.userId || null;
            
            this.init();
        }
        
        init() {
            this.trackPageView();
            this.setupEventListeners();
        }
        
        getOrCreateSessionId() {
            let sessionId = sessionStorage.getItem('liveinsight_session_id');
            if (!sessionId) {
                sessionId = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                sessionStorage.setItem('liveinsight_session_id', sessionId);
            }
            return sessionId;
        }
        
        async getCSRFToken() {
            let token = sessionStorage.getItem('csrf_token');
            let tokenTime = sessionStorage.getItem('csrf_token_time');
            
            // 토큰이 없거나 1시간 이상 지났으면 새로 발급
            if (!token || !tokenTime || (Date.now() - parseInt(tokenTime)) > 3600000) {
                try {
                    const response = await fetch(`${this.apiUrl}/api/csrf-token`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ session_id: this.sessionId })
                    });
                    
                    if (response.ok) {
                        const data = await response.json();
                        token = data.csrf_token;
                        sessionStorage.setItem('csrf_token', token);
                        sessionStorage.setItem('csrf_token_time', Date.now().toString());
                    }
                } catch (error) {
                    console.warn('Failed to get CSRF token:', error);
                    return '';
                }
            }
            
            return token || '';
        }
        
        async sendEvent(eventData) {
            try {
                const csrfToken = await this.getCSRFToken();
                const response = await fetch(`${this.apiUrl}/api/v1/events/collect`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-API-Key': this.apiKey,
                        'X-CSRF-Token': csrfToken,
                        'X-Session-ID': this.sessionId
                    },
                    body: JSON.stringify({
                        session_id: this.sessionId,
                        user_id: this.userId,
                        url: window.location.href,
                        ...eventData
                    })
                });
                
                if (!response.ok) {
                    console.warn('LiveInsight: Failed to send event');
                }
            } catch (error) {
                console.warn('LiveInsight: Error sending event:', error);
            }
        }
        
        trackPageView() {
            this.sendEvent({
                event_type: 'page_view',
                page_title: document.title,
                referrer: document.referrer
            });
        }
        
        trackClick(element, x, y) {
            this.sendEvent({
                event_type: 'click',
                element_id: element.id || null,
                element_class: element.className || null,
                element_text: element.textContent?.substring(0, 100) || null,
                x_position: x,
                y_position: y
            });
        }
        
        setupEventListeners() {
            // 클릭 이벤트 추적
            document.addEventListener('click', (e) => {
                this.trackClick(e.target, e.clientX, e.clientY);
            });
            
            // 페이지 이탈 시 세션 종료
            window.addEventListener('beforeunload', () => {
                navigator.sendBeacon(`${this.apiUrl}/api/v1/events/collect`, JSON.stringify({
                    session_id: this.sessionId,
                    user_id: this.userId,
                    event_type: 'page_exit',
                    url: window.location.href
                }));
            });
        }
    }
    
    // 전역 함수로 노출
    window.LiveInsight = {
        init: function(config) {
            if (!window._liveinsightTracker) {
                window._liveinsightTracker = new LiveInsightTracker(config || {});
            }
            return window._liveinsightTracker;
        }
    };
    
    // 자동 초기화 (설정이 있는 경우)
    if (window.liveinsightConfig) {
        window.LiveInsight.init(window.liveinsightConfig);
    }
})();