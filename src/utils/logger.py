import logging
import sys
from datetime import datetime
from src.config import settings

def setup_logger(name: str = "liveinsight") -> logging.Logger:
    """로거 설정"""
    logger = logging.getLogger(name)
    
    if logger.handlers:
        return logger
    
    # 로그 레벨 설정
    level = logging.DEBUG if settings.debug else logging.INFO
    logger.setLevel(level)
    
    # 포맷터 설정
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # 콘솔 핸들러
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    return logger

# 전역 로거
logger = setup_logger()