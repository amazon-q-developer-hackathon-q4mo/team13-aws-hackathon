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