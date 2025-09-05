/**
 * LiveInsight - 실시간 웹 분석 추적 스크립트
 * Version: 1.0.0
 * 
 * 사용법:
 * <script src="https://d28t8gs7tn78ne.cloudfront.net/js/liveinsight.js"></script>
 * <script>LiveInsight.init('your-site-key');</script>
 */

(function(window, document) {
    'use strict';

    // API 엔드포인트 설정
    var API_BASE_URL = 'https://k2eb4xeb24.execute-api.us-east-1.amazonaws.com/dev';
    var EVENTS_ENDPOINT = API_BASE_URL + '/api/events';
    
    // 설정값
    var CONFIG = {
        sessionTimeout: 30 * 60 * 1000, // 30분
        retryAttempts: 3,
        retryDelay: 1000, // 1초
        batchSize: 10,
        flushInterval: 5000 // 5초
    };

    /**
     * LiveInsight 메인 클래스
     */
    function LiveInsight() {
        this.siteKey = null;
        this.sessionId = null;
        this.userId = null;
        this.isInitialized = false;
        this.eventQueue = [];
        this.flushTimer = null;
        
        // 바인딩
        this.handlePageView = this.handlePageView.bind(this);
        this.handleBeforeUnload = this.handleBeforeUnload.bind(this);
        this.handleVisibilityChange = this.handleVisibilityChange.bind(this);
    }

    /**
     * LiveInsight 초기화
     */
    LiveInsight.prototype.init = function(siteKey, options) {
        if (this.isInitialized) {
            console.warn('LiveInsight: Already initialized');
            return;
        }

        if (!siteKey) {
            console.error('LiveInsight: Site key is required');
            return;
        }

        this.siteKey = siteKey;
        
        // 옵션 병합
        if (options) {
            for (var key in options) {
                if (CONFIG.hasOwnProperty(key)) {
                    CONFIG[key] = options[key];
                }
            }
        }

        // 세션 초기화
        this.initSession();
        
        // 이벤트 리스너 등록
        this.attachEventListeners();
        
        // 주기적 플러시 시작
        this.startPeriodicFlush();
        
        // 초기 페이지뷰 이벤트
        this.trackPageView();
        
        this.isInitialized = true;
        console.log('LiveInsight: Initialized successfully');
    };

    /**
     * 세션 초기화
     */
    LiveInsight.prototype.initSession = function() {
        var now = Date.now();
        var storedSession = this.getStoredSession();
        
        if (storedSession && (now - storedSession.lastActivity) < CONFIG.sessionTimeout) {
            // 기존 세션 재사용
            this.sessionId = storedSession.sessionId;
            this.userId = storedSession.userId;
        } else {
            // 새 세션 생성
            this.sessionId = this.generateUUID();
            this.userId = this.getOrCreateUserId();
        }
        
        // 세션 정보 저장
        this.saveSession(now);
    };

    /**
     * UUID 생성
     */
    LiveInsight.prototype.generateUUID = function() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = Math.random() * 16 | 0;
            var v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    };

    /**
     * 사용자 ID 가져오기 또는 생성
     */
    LiveInsight.prototype.getOrCreateUserId = function() {
        try {
            var userId = localStorage.getItem('liveinsight_user_id');
            if (!userId) {
                userId = this.generateUUID();
                localStorage.setItem('liveinsight_user_id', userId);
            }
            return userId;
        } catch (e) {
            return 'temp_' + Math.random().toString(36).substr(2, 9);
        }
    };

    /**
     * 저장된 세션 정보 가져오기
     */
    LiveInsight.prototype.getStoredSession = function() {
        try {
            var sessionData = localStorage.getItem('liveinsight_session');
            return sessionData ? JSON.parse(sessionData) : null;
        } catch (e) {
            return null;
        }
    };

    /**
     * 세션 정보 저장
     */
    LiveInsight.prototype.saveSession = function(timestamp) {
        try {
            var sessionData = {
                sessionId: this.sessionId,
                userId: this.userId,
                lastActivity: timestamp || Date.now(),
                startTime: timestamp || Date.now()
            };
            localStorage.setItem('liveinsight_session', JSON.stringify(sessionData));
        } catch (e) {
            // localStorage 사용 불가 시 무시
        }
    };

    /**
     * 이벤트 리스너 등록
     */
    LiveInsight.prototype.attachEventListeners = function() {
        var self = this;
        
        // 페이지 언로드 시
        if (window.addEventListener) {
            window.addEventListener('beforeunload', this.handleBeforeUnload, false);
        } else if (window.attachEvent) {
            window.attachEvent('onbeforeunload', this.handleBeforeUnload);
        }

        // 페이지 가시성 변경
        if (document.addEventListener) {
            document.addEventListener('visibilitychange', this.handleVisibilityChange, false);
        }

        // SPA 지원 (히스토리 변경)
        if (window.history && window.history.pushState) {
            var originalPushState = window.history.pushState;
            window.history.pushState = function() {
                originalPushState.apply(window.history, arguments);
                setTimeout(function() {
                    self.trackPageView();
                }, 100);
            };
        }
    };

    /**
     * 페이지뷰 추적
     */
    LiveInsight.prototype.trackPageView = function() {
        var eventData = {
            event_type: 'page_view',
            page_url: window.location.href,
            page_title: document.title,
            referrer: document.referrer,
            user_agent: navigator.userAgent,
            timestamp: Date.now(),
            session_id: this.sessionId,
            user_id: this.userId,
            site_key: this.siteKey
        };

        this.queueEvent(eventData);
    };

    /**
     * 커스텀 이벤트 추적
     */
    LiveInsight.prototype.track = function(eventType, properties) {
        if (!this.isInitialized) {
            console.warn('LiveInsight: Not initialized');
            return;
        }

        var eventData = {
            event_type: eventType,
            page_url: window.location.href,
            timestamp: Date.now(),
            session_id: this.sessionId,
            user_id: this.userId,
            site_key: this.siteKey
        };

        // 추가 속성 병합
        if (properties && typeof properties === 'object') {
            for (var key in properties) {
                if (properties.hasOwnProperty(key)) {
                    eventData[key] = properties[key];
                }
            }
        }

        this.queueEvent(eventData);
    };

    /**
     * 이벤트 큐에 추가
     */
    LiveInsight.prototype.queueEvent = function(eventData) {
        this.eventQueue.push(eventData);
        
        // 배치 크기 도달 시 즉시 전송
        if (this.eventQueue.length >= CONFIG.batchSize) {
            this.flushEvents();
        }
    };

    /**
     * 주기적 플러시 시작
     */
    LiveInsight.prototype.startPeriodicFlush = function() {
        var self = this;
        this.flushTimer = setInterval(function() {
            if (self.eventQueue.length > 0) {
                self.flushEvents();
            }
        }, CONFIG.flushInterval);
    };

    /**
     * 이벤트 전송
     */
    LiveInsight.prototype.flushEvents = function() {
        if (this.eventQueue.length === 0) return;

        var events = this.eventQueue.splice(0, CONFIG.batchSize);
        this.sendEvents(events);
    };

    /**
     * 서버로 이벤트 전송
     */
    LiveInsight.prototype.sendEvents = function(events, attempt) {
        attempt = attempt || 1;
        var self = this;

        // CSRF 토큰 가져오기
        this.getCSRFToken(function(csrfToken) {
            // Fetch API 또는 XMLHttpRequest 사용
            if (window.fetch) {
                fetch(EVENTS_ENDPOINT, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-Token': csrfToken,
                        'X-Session-ID': self.sessionId
                    },
                    body: JSON.stringify({ events: events })
                })
                .then(function(response) {
                    if (!response.ok) {
                        throw new Error('HTTP ' + response.status);
                    }
                    console.log('LiveInsight: Events sent successfully');
                })
                .catch(function(error) {
                    console.warn('LiveInsight: Failed to send events', self._sanitizeLogInput(error.message || 'Unknown error'));
                    self.handleSendError(events, attempt);
                });
            } else {
                self.fallbackXHR(events, attempt, csrfToken);
            }
        });
    };
    
    /**
     * CSRF 토큰 가져오기
     */
    LiveInsight.prototype.getCSRFToken = function(callback) {
        var token = this.getStoredCSRFToken();
        var self = this;
        
        if (token && this.isCSRFTokenValid(token)) {
            callback(token.value);
            return;
        }
        
        // 새 토큰 요청
        if (window.fetch) {
            fetch(API_BASE_URL + '/api/csrf-token', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ session_id: this.sessionId })
            })
            .then(function(response) {
                if (response.ok) {
                    return response.json();
                }
                throw new Error('Failed to get CSRF token');
            })
            .then(function(data) {
                self.storeCSRFToken(data.csrf_token);
                callback(data.csrf_token);
            })
            .catch(function(error) {
                console.warn('LiveInsight: Failed to get CSRF token', self._sanitizeLogInput(error.message || 'Unknown error'));
                callback('');
            });
        } else {
            callback('');
        }
    };
    
    /**
     * CSRF 토큰 저장
     */
    LiveInsight.prototype.storeCSRFToken = function(token) {
        try {
            var tokenData = {
                value: token,
                timestamp: Date.now()
            };
            sessionStorage.setItem('liveinsight_csrf_token', JSON.stringify(tokenData));
        } catch (e) {
            // 무시
        }
    };
    
    /**
     * 저장된 CSRF 토큰 가져오기
     */
    LiveInsight.prototype.getStoredCSRFToken = function() {
        try {
            var tokenData = sessionStorage.getItem('liveinsight_csrf_token');
            return tokenData ? JSON.parse(tokenData) : null;
        } catch (e) {
            return null;
        }
    };
    
    /**
     * CSRF 토큰 유효성 검사
     */
    LiveInsight.prototype.isCSRFTokenValid = function(tokenData) {
        if (!tokenData || !tokenData.timestamp) return false;
        // 1시간 유효
        return (Date.now() - tokenData.timestamp) < 3600000;
    };
    
    /**
     * 로그 인젝션 방지를 위한 입력 정제
     */
    LiveInsight.prototype._sanitizeLogInput = function(input) {
        if (typeof input !== 'string') {
            input = String(input);
        }
        
        // 개행문자 및 제어문자 제거
        var sanitized = input.replace(/[\r\n\t]/g, ' ');
        
        // 길이 제한
        if (sanitized.length > 100) {
            sanitized = sanitized.substring(0, 97) + '...';
        }
        
        return sanitized;
    };

    /**
     * XMLHttpRequest 폴백
     */
    LiveInsight.prototype.fallbackXHR = function(events, attempt, csrfToken) {
        var self = this;
        var xhr = new XMLHttpRequest();
        
        xhr.open('POST', EVENTS_ENDPOINT, true);
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.setRequestHeader('X-CSRF-Token', csrfToken || '');
        xhr.setRequestHeader('X-Session-ID', this.sessionId);
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                if (xhr.status >= 200 && xhr.status < 300) {
                    console.log('LiveInsight: Events sent successfully');
                } else {
                    console.warn('LiveInsight: Failed to send events', xhr.status);
                    self.handleSendError(events, attempt);
                }
            }
        };
        
        xhr.send(JSON.stringify({ events: events }));
    };

    /**
     * 전송 실패 처리
     */
    LiveInsight.prototype.handleSendError = function(events, attempt) {
        if (attempt < CONFIG.retryAttempts) {
            var self = this;
            setTimeout(function() {
                self.sendEvents(events, attempt + 1);
            }, CONFIG.retryDelay * attempt);
        } else {
            console.error('LiveInsight: Failed to send events after', CONFIG.retryAttempts, 'attempts');
        }
    };

    /**
     * 페이지뷰 핸들러
     */
    LiveInsight.prototype.handlePageView = function() {
        this.trackPageView();
    };

    /**
     * 페이지 언로드 핸들러
     */
    LiveInsight.prototype.handleBeforeUnload = function() {
        // 남은 이벤트 즉시 전송
        if (this.eventQueue.length > 0) {
            this.flushEvents();
        }
        
        // 세션 종료 이벤트
        this.track('session_end');
    };

    /**
     * 페이지 가시성 변경 핸들러
     */
    LiveInsight.prototype.handleVisibilityChange = function() {
        if (document.hidden) {
            this.track('page_hidden');
        } else {
            this.track('page_visible');
            this.saveSession(); // 활동 시간 업데이트
        }
    };

    /**
     * 정리
     */
    LiveInsight.prototype.destroy = function() {
        if (this.flushTimer) {
            clearInterval(this.flushTimer);
            this.flushTimer = null;
        }
        
        // 남은 이벤트 전송
        this.flushEvents();
        
        this.isInitialized = false;
    };

    // 전역 객체 생성
    var liveInsight = new LiveInsight();

    // 전역 네임스페이스에 노출
    window.LiveInsight = {
        init: function(siteKey, options) {
            liveInsight.init(siteKey, options);
        },
        track: function(eventType, properties) {
            liveInsight.track(eventType, properties);
        },
        destroy: function() {
            liveInsight.destroy();
        }
    };

})(window, document);