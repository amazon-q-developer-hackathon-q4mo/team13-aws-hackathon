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
        
    except ConnectionError:
        return HTMLResponse('<div class="error">데이터베이스 연결 실패</div>')
    except TimeoutError:
        return HTMLResponse('<div class="error">요청 시간 초과</div>')
    except Exception as e:
        # 로그에만 상세 오류 기록, 사용자에게는 일반적인 메시지
        import logging
        logging.error(f"Stats loading failed: {str(e)}")
        return HTMLResponse('<div class="error">통계 데이터를 불러올 수 없습니다.</div>')