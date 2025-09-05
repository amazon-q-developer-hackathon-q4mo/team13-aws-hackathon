import secrets
import hashlib
import time
from typing import Optional
from fastapi import Request, HTTPException

class CSRFProtection:
    def __init__(self, secret_key: str = "your-secret-key", token_lifetime: int = 3600):
        self.secret_key = secret_key
        self.token_lifetime = token_lifetime
    
    def generate_token(self, session_id: str) -> str:
        """CSRF 토큰 생성"""
        timestamp = str(int(time.time()))
        data = f"{session_id}:{timestamp}:{self.secret_key}"
        token = hashlib.sha256(data.encode()).hexdigest()
        return f"{timestamp}:{token}"
    
    def validate_token(self, token: str, session_id: str) -> bool:
        """CSRF 토큰 검증"""
        try:
            timestamp_str, token_hash = token.split(":", 1)
            timestamp = int(timestamp_str)
            
            # 토큰 만료 확인
            if time.time() - timestamp > self.token_lifetime:
                return False
            
            # 토큰 검증
            expected_data = f"{session_id}:{timestamp_str}:{self.secret_key}"
            expected_token = hashlib.sha256(expected_data.encode()).hexdigest()
            
            return token_hash == expected_token
        except (ValueError, IndexError):
            return False

csrf_protection = CSRFProtection()

def get_csrf_token(session_id: str) -> str:
    """CSRF 토큰 생성 헬퍼"""
    return csrf_protection.generate_token(session_id)

def verify_csrf_token(request: Request) -> bool:
    """CSRF 토큰 검증 의존성"""
    csrf_token = request.headers.get("X-CSRF-Token")
    session_id = request.headers.get("X-Session-ID")
    
    if not csrf_token or not session_id:
        raise HTTPException(status_code=403, detail="CSRF token required")
    
    if not csrf_protection.validate_token(csrf_token, session_id):
        raise HTTPException(status_code=403, detail="Invalid CSRF token")
    
    return True