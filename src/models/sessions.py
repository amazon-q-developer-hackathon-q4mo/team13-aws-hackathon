from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from uuid import uuid4
import time

class UserSession(BaseModel):
    session_id: str = Field(default_factory=lambda: str(uuid4()))
    is_active: str = "true"  # DynamoDB GSI에서 문자열 타입 요구
    last_activity: int = Field(default_factory=lambda: int(time.time()))
    start_time: int = Field(default_factory=lambda: int(time.time()))
    user_agent: Optional[str] = None
    initial_referrer: Optional[str] = None
    
    def update_activity(self):
        """
        세션의 마지막 활동 시간을 현재 시간으로 업데이트
        """
        self.last_activity = int(time.time())

class SessionStats(BaseModel):
    total_sessions: int = 0
    active_sessions: int = 0
    avg_duration: float = 0.0
    avg_page_views: float = 0.0
    bounce_rate: float = 0.0