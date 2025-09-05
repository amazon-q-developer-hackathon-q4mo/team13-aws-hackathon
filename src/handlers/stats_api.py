from fastapi import APIRouter, Depends
from src.services.analytics import AnalyticsService
from src.utils.response import success_response, error_response
from src.utils.validation import validate_api_key

router = APIRouter(prefix="/api/stats", tags=["Statistics"])
analytics_service = AnalyticsService()

@router.get("")
async def get_stats():
    """
    사용자 세션 통계 데이터를 조회하는 API 엔드포인트
    
    전체 세션 수, 활성 세션 수, 평균 세션 지속시간, 평균 페이지뷰,
    이탈률 등의 세션 관련 통계 지표를 제공합니다.
    
    Args:
        _ (bool): API 키 검증 의존성
    
    Returns:
        dict: 세션 통계 데이터 (SessionStats 모델의 JSON 형태)
    
    Raises:
        HTTPException: 세션 통계 조회 실패 시 500 에러
    
    Example:
        GET /api/v1/stats/sessions
        Response: {
            "success": true,
            "data": {
                "total_sessions": 150,
                "active_sessions": 23,
                "avg_duration": 245.5,
                "avg_page_views": 3.2,
                "bounce_rate": 0.35
            }
        }
    """
    try:
        stats = await analytics_service.get_session_analytics()
        return success_response(stats.model_dump())
    except Exception as e:
        return error_response(f"Error fetching session stats: {str(e)}", 500)

@router.get("/overview")
async def get_analytics_overview(_: bool = Depends(validate_api_key)):
    """
    전체 웹사이트 분석 개요를 제공하는 종합 API 엔드포인트
    
    실시간 통계와 세션 통계를 결합하여 대시보드에서 사용할 수 있는
    종합적인 분석 데이터를 한 번에 제공합니다.
    
    Args:
        _ (bool): API 키 검증 의존성
    
    Returns:
        dict: 실시간 통계와 세션 통계를 포함한 종합 분석 데이터
    
    Raises:
        HTTPException: 분석 데이터 조회 실패 시 500 에러
    
    Example:
        GET /api/v1/stats/overview
        Response: {
            "success": true,
            "data": {
                "realtime": {
                    "total_events": 1250,
                    "page_views": 890,
                    "clicks": 360
                },
                "sessions": {
                    "total_sessions": 150,
                    "active_sessions": 23
                }
            }
        }
    """
    try:
        realtime_stats = await analytics_service.get_realtime_stats()
        session_stats = await analytics_service.get_session_analytics()
        
        overview = {
            "realtime": realtime_stats,
            "sessions": session_stats.model_dump()
        }
        
        return success_response(overview)
    except Exception as e:
        return error_response(f"Error fetching analytics overview: {str(e)}", 500)