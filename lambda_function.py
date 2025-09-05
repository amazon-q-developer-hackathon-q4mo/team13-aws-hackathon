"""
AWS Lambda 핸들러 - 배포된 인프라와 호환
"""

from src.main import handler

def lambda_handler(event, context):
    """Lambda 진입점"""
    return handler(event, context)