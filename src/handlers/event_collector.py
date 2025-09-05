from fastapi import APIRouter, Request, Depends
from src.models.events import WebEvent, PageViewEvent, ClickEvent
from src.models.sessions import UserSession
from src.services.dynamodb import DynamoDBService
from src.utils.response import success_response, error_response
from src.utils.validation import validate_api_key, validate_event_type

router = APIRouter(prefix="/api/v1/events", tags=["Events"])
db_service = DynamoDBService()

@router.post("/collect")
async def collect_event(
    event_data: dict,
    request: Request,
    _: bool = Depends(validate_api_key)
):
    """
    웹 이벤트를 수집하고 처리하는 API 엔드포인트
    
    Args:
        event_data (dict): 이벤트 데이터 (event_type, session_id, user_id, url 등)
        request (Request): FastAPI 요청 객체 (IP, User-Agent 추출용)
        _ (bool): API 키 검증 의존성
    
    Returns:
        dict: 성공 시 event_id 포함한 응답, 실패 시 에러 메시지
    
    Raises:
        HTTPException: 이벤트 타입 검증 실패 또는 저장 실패 시
    
    Example:
        POST /api/v1/events/collect
        {
            "event_type": "page_view",
            "session_id": "sess_123",
            "user_id": "user_456",
            "url": "https://example.com/page"
        }
    """
    try:
        # 클라이언트 정보 추출
        event_data['ip_address'] = request.client.host
        event_data['user_agent'] = request.headers.get('user-agent')
        
        # 이벤트 타입 검증
        validate_event_type(event_data.get('event_type', ''))
        
        # 이벤트 객체 생성
        if event_data['event_type'] == 'page_view':
            event = PageViewEvent(**event_data)
        elif event_data['event_type'] == 'click':
            event = ClickEvent(**event_data)
        else:
            event = WebEvent(**event_data)
        
        # 이벤트 저장
        success = await db_service.save_event(event)
        if not success:
            return error_response("Failed to save event", 500)
        
        # 세션 업데이트
        await update_session(event)
        
        return success_response({"event_id": event.event_id})
        
    except Exception as e:
        return error_response(f"Error processing event: {str(e)}", 500)

async def update_session(event: WebEvent):
    """
    이벤트 기반으로 사용자 세션 정보를 업데이트
    
    기존 세션이 있으면 통계를 업데이트하고, 없으면 새 세션을 생성합니다.
    페이지뷰와 클릭 이벤트에 따라 각각의 카운터를 증가시킵니다.
    
    Args:
        event (WebEvent): 처리할 웹 이벤트 객체
    
    Returns:
        None
    
    Raises:
        Exception: 세션 조회, 생성, 또는 저장 중 오류 발생 시
                  (오류는 로그로 출력되고 무시됨)
    
    Note:
        - 새 세션 생성 시 entry_url을 현재 이벤트 URL로 설정
        - 모든 이벤트에서 exit_url을 현재 URL로 업데이트
        - 세션의 last_activity 시간을 현재 시간으로 갱신
    """
    try:
        session = await db_service.get_session(event.session_id)
        
        if not session:
            # 새 세션 생성
            session = UserSession(
                session_id=event.session_id,
                user_id=event.user_id,
                entry_url=event.url,
                user_agent=event.user_agent,
                ip_address=event.ip_address
            )
        
        # 세션 통계 업데이트
        if event.event_type == 'page_view':
            session.page_views += 1
        elif event.event_type == 'click':
            session.total_clicks += 1
        
        session.exit_url = event.url
        session.update_activity()
        
        await db_service.save_session(session)
        
    except Exception as e:
        print(f"Error updating session: {e}")