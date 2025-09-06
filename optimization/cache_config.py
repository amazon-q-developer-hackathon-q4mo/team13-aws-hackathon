"""
Django 캐시 설정 및 최적화
"""

# Django settings.py에 추가할 캐시 설정
CACHE_SETTINGS = {
    'CACHES': {
        'default': {
            'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
            'LOCATION': 'liveinsight-cache',
            'TIMEOUT': 300,  # 5분
            'OPTIONS': {
                'MAX_ENTRIES': 1000,
            }
        },
        'sessions': {
            'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
            'LOCATION': 'sessions-cache',
            'TIMEOUT': 1800,  # 30분
            'OPTIONS': {
                'MAX_ENTRIES': 5000,
            }
        },
        'statistics': {
            'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
            'LOCATION': 'stats-cache',
            'TIMEOUT': 600,  # 10분
            'OPTIONS': {
                'MAX_ENTRIES': 100,
            }
        }
    },
    
    # 캐시 키 프리픽스
    'CACHE_MIDDLEWARE_KEY_PREFIX': 'liveinsight',
    'CACHE_MIDDLEWARE_SECONDS': 300,
}

# Redis 캐시 설정 (프로덕션용)
REDIS_CACHE_SETTINGS = {
    'CACHES': {
        'default': {
            'BACKEND': 'django_redis.cache.RedisCache',
            'LOCATION': 'redis://127.0.0.1:6379/1',
            'OPTIONS': {
                'CLIENT_CLASS': 'django_redis.client.DefaultClient',
                'SERIALIZER': 'django_redis.serializers.json.JSONSerializer',
                'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
            },
            'TIMEOUT': 300,
        }
    }
}

# 캐시 데코레이터 사용 예시
"""
from django.core.cache import cache
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator

# 뷰 캐싱
@cache_page(60 * 5)  # 5분 캐시
def statistics_view(request):
    pass

# 메서드 캐싱
@method_decorator(cache_page(60 * 10), name='dispatch')
class StatisticsViewSet(viewsets.ViewSet):
    pass

# 수동 캐싱
def get_cached_sessions():
    cache_key = 'active_sessions'
    sessions = cache.get(cache_key)
    
    if sessions is None:
        sessions = db_client.get_active_sessions()
        cache.set(cache_key, sessions, 300)  # 5분 캐시
    
    return sessions
"""