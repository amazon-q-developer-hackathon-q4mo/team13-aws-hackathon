from fastapi import APIRouter, Depends
from src.services.analytics import AnalyticsService
from src.utils.response import success_response, error_response
from src.utils.validation import validate_api_key

router = APIRouter(prefix="/api/v1/realtime", tags=["Realtime"])
analytics_service = AnalyticsService()

@router.get("/stats")
async def get_realtime_stats(_: bool = Depends(validate_api_key)):
    """
    실시간 웹사이트 통계 데이터를 조회하는 API 엔드포인트
    
    최근 이벤트를 기반으로 실시간 통계를 계산하여 반환합니다.
    페이지뷰, 클릭 수, 시간대별 분포, 인기 페이지 등의 정보를 제공합니다.
    
    Args:
        _ (bool): API 키 검증 의존성
    
    Returns:
        dict: 실시간 통계 데이터 (총 이벤트 수, 페이지뷰, 클릭 수, 시간대별 분포 등)
    
    Raises:
        HTTPException: 통계 데이터 조회 실패 시 500 에러
    
    Example:
        GET /api/v1/realtime/stats
        Response: {
            "success": true,
            "data": {
                "total_events": 1250,
                "page_views": 890,
                "clicks": 360,
                "hourly_distribution": {...},
                "popular_pages": [...]
            }
        }
    """
    try:
        stats = await analytics_service.get_realtime_stats()
        return success_response(stats)
    except Exception as e:
        return error_response(f"Error fetching realtime stats: {str(e)}", 500)

@router.get("/events")
async def get_recent_events(limit: int = 50, _: bool = Depends(validate_api_key)):
    """
    최근 발생한 웹 이벤트 목록을 조회하는 API 엔드포인트
    
    지정된 개수만큼 최근 이벤트를 시간순으로 조회하여 반환합니다.
    실시간 모니터링 및 디버깅 목적으로 사용됩니다.
    
    Args:
        limit (int): 조회할 이벤트 개수 (기본값: 50, 최대 1000 권장)
        _ (bool): API 키 검증 의존성
    
    Returns:
        dict: 최근 이벤트 목록을 포함한 성공 응답
    
    Raises:
        HTTPException: 이벤트 조회 실패 시 500 에러
    
    Example:
        GET /api/v1/realtime/events?limit=100
        Response: {
            "success": true,
            "data": [
                {
                    "event_id": "evt_123",
                    "event_type": "page_view",
                    "url": "https://example.com",
                    "timestamp": "2024-01-15T10:30:00Z"
                }
            ]
        }
    """
    try:
        db_service = analytics_service.db
        events = await db_service.get_recent_events(limit)
        return success_response(events)
    except Exception as e:
        return error_response(f"Error fetching recent events: {str(e)}", 500)