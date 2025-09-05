import os
from typing import Optional
from fastapi import Header, HTTPException

def validate_api_key(x_api_key: Optional[str] = Header(None)) -> bool:
    """
    HTTP 헤더에서 API 키를 추출하여 유효성 검증
    
    X-API-Key 헤더에서 API 키를 추출하고 환경변수에 설정된 값과 비교합니다.
    개발 환경에서는 API_KEY 환경변수가 없으면 검증을 생략합니다.
    
    Args:
        x_api_key (Optional[str]): HTTP X-API-Key 헤더 값
    
    Returns:
        bool: 검증 성공 시 True
    
    Raises:
        HTTPException: API 키가 없거나 잘못된 경우 401 에러
    
    Example:
        # 헤더에 X-API-Key: your-api-key 포함
        # 유효한 경우 True 반환, 잘못된 경우 HTTPException 발생
    
    Note:
        - FastAPI Depends로 사용되어 자동으로 헤더 추출
        - 개발 환경에서는 API_KEY 환경변수 없으면 검증 생략
        - 프로덕션에서는 반드시 API_KEY 환경변수 설정 필요
    """
    expected_key = os.getenv('API_KEY')
    if not expected_key:
        return True  # 개발 환경에서는 API 키 검증 생략
    
    if not x_api_key or x_api_key != expected_key:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    return True

def validate_session_id(session_id: str) -> bool:
    """
    세션 ID의 형식과 길이를 검증
    
    세션 ID가 비어있지 않고 최소 길이 요구사항을 만족하는지 확인합니다.
    유효하지 않은 세션 ID의 경우 HTTP 400 에러를 발생시킵니다.
    
    Args:
        session_id (str): 검증할 세션 ID 문자열
    
    Returns:
        bool: 검증 성공 시 True
    
    Raises:
        HTTPException: 세션 ID가 비어있거나 10자 미만인 경우 400 에러
    
    Example:
        validate_session_id("sess_1234567890")  # True 반환
        validate_session_id("short")  # HTTPException 발생
        validate_session_id("")  # HTTPException 발생
    
    Note:
        - 최소 길이: 10자
        - 빈 문자열 또는 None 값 불허
        - UUID 또는 사용자 정의 형식 모두 허용
    """
    if not session_id or len(session_id) < 10:
        raise HTTPException(status_code=400, detail="Invalid session ID")
    return True

def validate_event_type(event_type: str) -> bool:
    """
    이벤트 타입이 허용된 목록에 있는지 검증
    
    지원되는 이벤트 타입 목록과 비교하여 유효성을 확인합니다.
    지원되지 않는 이벤트 타입의 경우 HTTP 400 에러를 발생시킵니다.
    
    Args:
        event_type (str): 검증할 이벤트 타입 문자열
    
    Returns:
        bool: 검증 성공 시 True
    
    Raises:
        HTTPException: 지원되지 않는 이벤트 타입인 경우 400 에러
    
    Example:
        validate_event_type("page_view")  # True 반환
        validate_event_type("click")  # True 반환
        validate_event_type("invalid_type")  # HTTPException 발생
    
    Note:
        - 지원 타입: page_view, click, scroll, form_submit
        - 대소문자 구분
        - 새로운 이벤트 타입 추가 시 valid_types 목록 업데이트 필요
    """
    valid_types = ['page_view', 'click', 'scroll', 'form_submit']
    if event_type not in valid_types:
        raise HTTPException(status_code=400, detail=f"Invalid event type. Must be one of: {valid_types}")
    return True