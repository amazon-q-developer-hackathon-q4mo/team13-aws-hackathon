import json
import time
from typing import Any, Optional, Dict
from src.config import settings
from src.utils.logger import logger

class InMemoryCache:
    def __init__(self):
        self._cache: Dict[str, Dict[str, Any]] = {}
        self.default_ttl = settings.cache_ttl_seconds
    
    def get(self, key: str) -> Optional[Any]:
        """캐시에서 값 조회"""
        if key not in self._cache:
            return None
        
        item = self._cache[key]
        
        # TTL 확인
        if time.time() > item['expires_at']:
            del self._cache[key]
            logger.debug(f"Cache expired: {self._sanitize_log_input(key)}")
            return None
        
        logger.debug(f"Cache hit: {self._sanitize_log_input(key)}")
        return item['value']
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """캐시에 값 저장"""
        ttl = ttl or self.default_ttl
        expires_at = time.time() + ttl
        
        self._cache[key] = {
            'value': value,
            'expires_at': expires_at,
            'created_at': time.time()
        }
        
        logger.debug(f"Cache set: {self._sanitize_log_input(key)} (TTL: {ttl}s)")
    
    def delete(self, key: str) -> bool:
        """캐시에서 값 삭제"""
        if key in self._cache:
            del self._cache[key]
            logger.debug(f"Cache deleted: {self._sanitize_log_input(key)}")
            return True
        return False
    
    def clear(self) -> None:
        """전체 캐시 삭제"""
        self._cache.clear()
        logger.info("Cache cleared")
    
    def cleanup_expired(self) -> int:
        """만료된 캐시 항목 정리"""
        current_time = time.time()
        expired_keys = [
            key for key, item in self._cache.items()
            if current_time > item['expires_at']
        ]
        
        for key in expired_keys:
            del self._cache[key]
        
        if expired_keys:
            logger.info(f"Cleaned up {len(expired_keys)} expired cache items")
        
        return len(expired_keys)
    
    def _sanitize_log_input(self, input_str: str) -> str:
        """로그 인젝션 방지를 위한 입력 문자열 정제"""
        if not isinstance(input_str, str):
            input_str = str(input_str)
        
        # 개행 문자 및 제어 문자 제거
        sanitized = input_str.replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')
        
        # 길이 제한 (로그 크기 제한)
        if len(sanitized) > 100:
            sanitized = sanitized[:97] + '...'
        
        return sanitized

# 전역 캐시 인스턴스
cache = InMemoryCache()