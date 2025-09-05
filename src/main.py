import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from mangum import Mangum
from src.config import settings
from src.middleware.error_handler import ErrorHandlerMiddleware
from src.utils.logger import logger
from src.handlers import event_collector, realtime_api, stats_api, dashboard, stats_htmx, csrf_token

app = FastAPI(
    title="LiveInsight API",
    description="실시간 웹 분석 서비스",
    version="0.1.0",
    debug=settings.debug
)

# 미들웨어 설정
app.add_middleware(ErrorHandlerMiddleware)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 서빙
try:
    if os.path.exists("frontend/static"):
        app.mount("/static", StaticFiles(directory="frontend/static"), name="static")
    else:
        logger.warning("Static files directory not found: frontend/static")
except Exception as e:
    logger.error(f"Failed to mount static files: {e}")

# 라우터 등록
app.include_router(csrf_token.router)
app.include_router(event_collector.router)
app.include_router(realtime_api.router)
app.include_router(stats_api.router)
app.include_router(dashboard.router)
app.include_router(stats_htmx.router)

@app.get("/health")
async def health_check():
    """
    API 서비스 상태를 확인하는 헬스체크 엔드포인트
    
    로드밸런서나 모니터링 시스템에서 서비스 가용성을 확인하는 데 사용됩니다.
    간단한 상태 정보를 반환하여 서비스가 정상적으로 동작하는지 확인할 수 있습니다.
    
    Returns:
        dict: 서비스 상태 정보
            - status: "healthy" (서비스 정상 상태)
            - service: "LiveInsight API" (서비스 이름)
    
    Example:
        GET /health
        Response: {"status": "healthy", "service": "LiveInsight API"}
    
    Note:
        - 인증 불필요
        - 항상 200 OK 응답
        - AWS ALB/ELB 헬스체크에 사용 가능
    """
    return {
        "status": "healthy", 
        "service": "LiveInsight API",
        "environment": settings.environment,
        "version": "0.1.0"
    }

@app.get("/")
async def root():
    """
    API 루트 엔드포인트로 서비스 정보와 사용 가능한 엔드포인트 목록을 제공
    
    API 서비스의 기본 정보와 사용 가능한 모든 엔드포인트 목록을 반환합니다.
    개발자가 API 구조를 파악하고 테스트할 때 유용한 정보를 제공합니다.
    
    Returns:
        dict: API 서비스 정보
            - message: 서비스 이름
            - version: 현재 API 버전
            - endpoints: 사용 가능한 엔드포인트 목록
    
    Example:
        GET /
        Response: {
            "message": "LiveInsight API",
            "version": "0.1.0",
            "endpoints": ["/health", "/api/v1/events/collect", ...]
        }
    
    Note:
        - 인증 불필요
        - API 문서화 및 디스커버리 목적
        - 새 엔드포인트 추가 시 endpoints 목록 업데이트 필요
    """
    return {
        "message": "LiveInsight API",
        "version": "0.1.0",
        "endpoints": [
            "/health",
            "/api/events",
            "/api/realtime",
            "/api/stats"
        ]
    }

# 시작 이벤트
@app.on_event("startup")
async def startup_event():
    logger.info(f"LiveInsight API starting up - Environment: {settings.environment}")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("LiveInsight API shutting down")

# Lambda 핸들러
handler = Mangum(app)