import os
from typing import Optional
from pydantic_settings import BaseSettings

def _safe_int(value: str, default: int) -> int:
    """안전한 정수 변환"""
    try:
        return int(value)
    except (ValueError, TypeError):
        return default

class Settings(BaseSettings):
    # 환경 설정
    environment: str = os.getenv("ENVIRONMENT", "dev")
    debug: bool = os.getenv("DEBUG", "true").lower() == "true"
    
    # AWS 자격 증명
    aws_access_key_id: Optional[str] = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_access_key: Optional[str] = os.getenv("AWS_SECRET_ACCESS_KEY")
    
    # AWS 설정
    aws_region: str = os.getenv("AWS_REGION", "us-east-1")
    events_table: str = os.getenv("EVENTS_TABLE", "liveinsight-events-dev")
    sessions_table: str = os.getenv("SESSIONS_TABLE", "liveinsight-sessions-dev")
    
    # API 설정
    api_key: Optional[str] = os.getenv("API_KEY")
    cors_origins: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # 성능 설정
    max_events_per_request: int = _safe_int(os.getenv("MAX_EVENTS_PER_REQUEST", "1000"), 1000)
    cache_ttl_seconds: int = _safe_int(os.getenv("CACHE_TTL_SECONDS", "60"), 60)

    class Config:
        env_file = ".env"

# 전역 설정 인스턴스
settings = Settings()