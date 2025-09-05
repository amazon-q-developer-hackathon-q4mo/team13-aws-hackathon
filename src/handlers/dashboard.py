from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from src.services.analytics import AnalyticsService
from datetime import datetime

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])
templates = Jinja2Templates(directory="frontend/templates")
analytics_service = AnalyticsService()

@router.get("/", response_class=HTMLResponse)
async def dashboard_page(request: Request):
    """대시보드 메인 페이지"""
    return templates.TemplateResponse("dashboard.html", {"request": request})

@router.get("/chart/hourly")
async def hourly_chart():
    """시간대별 차트 데이터 (HTML 조각)"""
    stats = await analytics_service.get_realtime_stats()
    hourly_data = stats.get('hourly_distribution', {})
    
    # 간단한 바 차트 HTML 생성
    chart_html = '<div style="display: flex; align-items: end; gap: 4px; height: 200px;">'
    
    max_value = max(hourly_data.values()) if hourly_data else 1
    
    for hour in range(24):
        hour_key = f"{hour:02d}:00"
        value = hourly_data.get(hour_key, 0)
        height = (value / max_value * 180) if max_value > 0 else 0
        
        chart_html += f'''
        <div style="
            background: #3b82f6; 
            width: 20px; 
            height: {height}px; 
            margin-top: {200-height-20}px;
            border-radius: 2px;
            position: relative;
        " title="{hour_key}: {value}개">
            <div style="
                position: absolute; 
                bottom: -20px; 
                font-size: 10px; 
                color: #64748b;
                transform: rotate(-45deg);
                transform-origin: left;
            ">{hour}</div>
        </div>
        '''
    
    chart_html += '</div>'
    return HTMLResponse(chart_html)

@router.get("/popular-pages")
async def popular_pages():
    """인기 페이지 목록 (HTML 조각)"""
    stats = await analytics_service.get_realtime_stats()
    pages = stats.get('popular_pages', [])
    
    if not pages:
        return HTMLResponse('<div class="loading">데이터가 없습니다.</div>')
    
    html = '<div style="space-y: 8px;">'
    for i, page in enumerate(pages[:10]):
        html += f'''
        <div style="
            display: flex; 
            justify-content: space-between; 
            padding: 8px 0; 
            border-bottom: 1px solid #f1f5f9;
        ">
            <div style="
                font-size: 14px; 
                color: #334155;
                max-width: 400px;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
            ">{i+1}. {page['url']}</div>
            <div style="
                font-weight: 600; 
                color: #3b82f6;
            ">{page['views']}</div>
        </div>
        '''
    html += '</div>'
    
    return HTMLResponse(html)

@router.get("/recent-events")
async def recent_events():
    """최근 이벤트 목록 (HTML 조각)"""
    events = await analytics_service.db.get_recent_events(20)
    
    if not events:
        return HTMLResponse('<div class="loading">이벤트가 없습니다.</div>')
    
    html = ''
    for event in events[:20]:
        event_type = event.get('event_type', 'unknown')
        url = event.get('url', '')
        timestamp = event.get('timestamp', '')
        
        # 시간 포맷팅
        try:
            dt = datetime.fromisoformat(timestamp)
            time_str = dt.strftime('%H:%M:%S')
        except:
            time_str = timestamp
        
        html += f'''
        <div class="event-item">
            <div>
                <span class="event-type {event_type}">{event_type}</span>
                <div class="event-url">{url}</div>
            </div>
            <div class="event-time">{time_str}</div>
        </div>
        '''
    
    return HTMLResponse(html)