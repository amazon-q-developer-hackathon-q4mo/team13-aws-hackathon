# 멀티스테이지 빌드
FROM python:3.11-slim as builder

WORKDIR /app

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성 설치
COPY ../pyproject.toml ../uv.lock ./
RUN pip install uv && uv sync --frozen

# 프로덕션 스테이지
FROM python:3.11-slim

# non-root 사용자 생성
RUN groupadd -r django && useradd -r -g django django

WORKDIR /app

# 런타임 의존성만 설치
RUN apt-get update && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# 빌드 스테이지에서 가상환경 복사
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# 애플리케이션 코드 복사
COPY . .
COPY ../static ./static

# 정적 파일 수집
RUN python manage.py collectstatic --noinput

# 권한 설정
RUN chown -R django:django /app
USER django

# 헬스체크 엔드포인트
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health/')" || exit 1

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "liveinsight.wsgi:application"]