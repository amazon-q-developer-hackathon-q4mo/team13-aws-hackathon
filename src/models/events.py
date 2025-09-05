from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from uuid import uuid4
import time

class WebEvent(BaseModel):
    session_id: str
    timestamp: int = Field(default_factory=lambda: int(time.time()))
    event_type: str  # page_view, click, scroll, form_submit
    page_url: str
    user_agent: Optional[str] = None
    referrer: Optional[str] = None
    ttl: int = Field(default_factory=lambda: int(time.time()) + 86400)  # 24시간 후

class PageViewEvent(WebEvent):
    event_type: str = "page_view"

class ClickEvent(WebEvent):
    event_type: str = "click"