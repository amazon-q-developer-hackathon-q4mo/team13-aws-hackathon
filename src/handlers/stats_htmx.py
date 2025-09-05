from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from src.services.analytics import AnalyticsService

router = APIRouter(prefix="/api/v1/realtime", tags=["HTMX"])
analytics_service = AnalyticsService()

@router.get("/stats", response_class=HTMLResponse)
async def get_stats_html():
    """HTMX용 통계 HTML 조각"""
    try:
        stats = await analytics_service.get_realtime_stats()
        
        html = f'''
        <div class="stat-card">
            <h3>총 이벤트</h3>
            <div class="stat-value">{stats.get('total_events', 0):,}</div>
        </div>
        <div class="stat-card">
            <h3>페이지뷰</h3>
            <div class="stat-value">{stats.get('page_views', 0):,}</div>
        </div>
        <div class="stat-card">
            <h3>클릭</h3>
            <div class="stat-value">{stats.get('clicks', 0):,}</div>
        </div>
        <div class="stat-card">
            <h3>마지막 업데이트</h3>
            <div class="stat-value" style="font-size: 0.875rem;">방금 전</div>
        </div>
        '''
        
        return HTMLResponse(html)
        
    except Exception as e:
        return HTMLResponse(f'<div class="error">통계 로딩 실패: {str(e)}</div>')