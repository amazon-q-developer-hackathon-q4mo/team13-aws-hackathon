from typing import Any, Dict, Optional
from fastapi import HTTPException
from fastapi.responses import JSONResponse

def success_response(data: Any = None, message: str = "Success") -> Dict[str, Any]:
    """
    API 성공 응답을 일관된 형식으로 생성
    
    모든 API 엔드포인트에서 사용하는 표준 성공 응답 포맷을 생성합니다.
    success 필드를 true로 설정하고, 선택적으로 데이터와 메시지를 포함합니다.
    
    Args:
        data (Any, optional): 응답에 포함할 데이터. None이면 data 필드 제외
        message (str): 성공 메시지 (기본값: "Success")
    
    Returns:
        Dict[str, Any]: 표준 성공 응답 딕셔너리
            - success: True
            - message: 성공 메시지
            - data: 응답 데이터 (있는 경우만)
    
    Example:
        success_response({"count": 10}, "Data retrieved")
        # Returns: {"success": True, "message": "Data retrieved", "data": {"count": 10}}
        
        success_response()
        # Returns: {"success": True, "message": "Success"}
    """
    response = {
        "success": True,
        "message": message
    }
    if data is not None:
        response["data"] = data
    return response

def error_response(message: str, status_code: int = 400, details: Optional[Dict] = None) -> HTTPException:
    """
    API 에러 응답을 일관된 형식으로 생성하고 HTTPException 발생
    
    에러 발생 시 표준 형식의 에러 응답을 생성하고 HTTPException을 발생시킵니다.
    FastAPI가 자동으로 에러 응답을 클라이언트에게 전송합니다.
    
    Args:
        message (str): 에러 메시지
        status_code (int): HTTP 상태 코드 (기본값: 400)
        details (Optional[Dict]): 추가 에러 세부 정보
    
    Returns:
        HTTPException: FastAPI HTTPException 객체
    
    Raises:
        HTTPException: 지정된 상태 코드와 메시지로 예외 발생
    
    Example:
        error_response("Invalid input", 400, {"field": "email"})
        # Raises HTTPException with status 400 and structured error data
        
        error_response("Not found", 404)
        # Raises HTTPException with status 404
    
    Note:
        - 이 함수는 예외를 발생시키므로 반환값을 받을 수 없음
        - FastAPI가 자동으로 JSON 에러 응답으로 변환
    """
    error_data = {
        "success": False,
        "message": message
    }
    if details:
        error_data["details"] = details
    
    raise HTTPException(status_code=status_code, detail=error_data)

def cors_response(data: Any) -> JSONResponse:
    """CORS 헤더가 포함된 응답"""
    return JSONResponse(
        content=data,
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*"
        }
    )