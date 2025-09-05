# Phase 1: 초기 설정 (1시간) - 개발자 B

## 목표
Django 프로젝트 설정 및 개발 환경 구성

## 작업 내용

### 1. 프로젝트 구조 설정 (30분)

**Django 프로젝트 생성**
```bash
# uv로 프로젝트 초기화 및 가상환경 생성
uv init --python 3.11
uv add django djangorestframework django-cors-headers boto3 python-dotenv

# Django 프로젝트 생성
uv run django-admin startproject liveinsight .
cd liveinsight
uv run python manage.py startapp analytics
uv run python manage.py startapp dashboard
```

**프로젝트 구조**
```
liveinsight/
├── manage.py
├── liveinsight/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── analytics/          # API 앱
│   ├── models.py
│   ├── views.py
│   ├── serializers.py
│   └── urls.py
├── dashboard/          # 대시보드 앱
│   ├── views.py
│   ├── urls.py
│   └── templates/
└── static/
    ├── css/
    ├── js/
    └── libs/
```

**pyproject.toml 의존성 (uv가 자동 생성)**
```toml
[project]
dependencies = [
    "django>=4.2.7",
    "djangorestframework>=3.14.0",
    "django-cors-headers>=4.3.1",
    "boto3>=1.29.7",
    "python-dotenv>=1.0.0",
]
```

### 2. 개발 환경 구성 (30분)

**uv 사용 명령어**
```bash
# 개발 서버 실행
uv run python manage.py runserver

# 마이그레이션
uv run python manage.py makemigrations
uv run python manage.py migrate
```

**settings.py 기본 설정**
```python
import os
from dotenv import load_dotenv

load_dotenv()

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'analytics',
    'dashboard',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# CORS 설정
CORS_ALLOW_ALL_ORIGINS = True

# AWS 설정
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_DEFAULT_REGION = 'us-east-1'

# DynamoDB 테이블 설정
EVENTS_TABLE = os.getenv('EVENTS_TABLE', 'LiveInsight-Events')
SESSIONS_TABLE = os.getenv('SESSIONS_TABLE', 'LiveInsight-Sessions')
ACTIVE_SESSIONS_TABLE = os.getenv('ACTIVE_SESSIONS_TABLE', 'LiveInsight-ActiveSessions')

# DRF 설정
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20
}
```

**.env 파일 생성**
```env
DEBUG=True
SECRET_KEY=your-secret-key-here
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
EVENTS_TABLE=LiveInsight-Events
SESSIONS_TABLE=LiveInsight-Sessions
ACTIVE_SESSIONS_TABLE=LiveInsight-ActiveSessions
```

**URL 라우팅 설정**
```python
# liveinsight/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('analytics.urls')),
    path('', include('dashboard.urls')),
]
```

## 완료 기준
- [ ] Django 프로젝트 생성 완료
- [ ] uv로 가상환경 및 패키지 설정
- [ ] 기본 앱 구조 생성 (analytics, dashboard)
- [ ] settings.py 기본 설정 완료
- [ ] URL 라우팅 구조 설정