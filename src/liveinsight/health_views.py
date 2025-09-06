from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from analytics.dynamodb_client import db_client
import logging

logger = logging.getLogger(__name__)

@require_http_methods(["GET"])
def health_check(request):
    """헬스체크 엔드포인트"""
    try:
        # DynamoDB 연결 테스트
        db_client.get_active_sessions()
        
        return JsonResponse({
            'status': 'healthy',
            'service': 'liveinsight',
            'database': 'connected'
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return JsonResponse({
            'status': 'unhealthy',
            'service': 'liveinsight',
            'database': 'disconnected',
            'error': str(e)
        }, status=503)