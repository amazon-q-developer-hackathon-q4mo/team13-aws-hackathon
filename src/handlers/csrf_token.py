from fastapi import APIRouter, Request
from src.middleware.csrf import get_csrf_token
from src.utils.response import success_response, error_response
from pydantic import BaseModel

router = APIRouter(prefix="/api", tags=["CSRF"])

class CSRFTokenRequest(BaseModel):
    session_id: str

@router.post("/csrf-token")
async def get_csrf_token_endpoint(request: CSRFTokenRequest):
    """
    CSRF 토큰 발급 엔드포인트
    
    Args:
        request (CSRFTokenRequest): 세션 ID를 포함한 요청
    
    Returns:
        dict: CSRF 토큰을 포함한 응답
    """
    try:
        csrf_token = get_csrf_token(request.session_id)
        return success_response({"csrf_token": csrf_token})
    except Exception as e:
        return error_response(f"Failed to generate CSRF token: {str(e)}", 500)