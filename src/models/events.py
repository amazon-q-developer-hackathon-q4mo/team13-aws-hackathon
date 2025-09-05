from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from uuid import uuid4

class WebEvent(BaseModel):
    event_id: str = Field(default_factory=lambda: str(uuid4()))
    session_id: str
    user_id: Optional[str] = None
    event_type: str  # page_view, click, scroll, form_submit
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    url: str
    user_agent: Optional[str] = None
    ip_address: Optional[str] = None
    properties: Dict[str, Any] = Field(default_factory=dict)

class PageViewEvent(WebEvent):
    event_type: str = "page_view"
    page_title: Optional[str] = None
    referrer: Optional[str] = None

class ClickEvent(WebEvent):
    event_type: str = "click"
    element_id: Optional[str] = None
    element_class: Optional[str] = None
    element_text: Optional[str] = None
    x_position: Optional[int] = None
    y_position: Optional[int] = None