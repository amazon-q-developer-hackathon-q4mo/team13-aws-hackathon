from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from uuid import uuid4

class UserSession(BaseModel):
    session_id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: Optional[str] = None
    start_time: datetime = Field(default_factory=datetime.utcnow)
    last_activity: datetime = Field(default_factory=datetime.utcnow)
    page_views: int = 0
    total_clicks: int = 0
    duration_seconds: int = 0
    entry_url: Optional[str] = None
    exit_url: Optional[str] = None
    user_agent: Optional[str] = None
    ip_address: Optional[str] = None
    is_active: bool = True
    
    def update_activity(self):
        """
        세션의 마지막 활동 시간을 현재 시간으로 업데이트하고 지속시간을 재계산
        
        새로운 이벤트가 발생할 때마다 호출되어 세션의 활성 상태를 유지합니다.
        지속시간은 세션 시작 시간부터 현재까지의 총 시간(초)으로 계산됩니다.
        
        Returns:
            None
        
        Note:
            - last_activity는 UTC 시간으로 설정
            - duration_seconds는 정수값으로 저장 (소수점 제거)
            - 세션 타임아웃 및 비활성 세션 처리에 사용
        """
        self.last_activity = datetime.utcnow()
        self.duration_seconds = int((self.last_activity - self.start_time).total_seconds())

class SessionStats(BaseModel):
    total_sessions: int = 0
    active_sessions: int = 0
    avg_duration: float = 0.0
    avg_page_views: float = 0.0
    bounce_rate: float = 0.0