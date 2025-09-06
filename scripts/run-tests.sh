#!/bin/bash
set -e

# Phase 7 통합 테스트 실행 스크립트

TEST_TYPE=${1:-all}
API_BASE_URL=${2:-}
LAMBDA_URL=${3:-}

echo "🧪 Running Phase 7 integration tests..."

# 필수 패키지 설치
echo "📦 Installing test dependencies..."
pip install aiohttp boto3 requests statistics

case $TEST_TYPE in
  "e2e"|"integration")
    if [ -z "$API_BASE_URL" ] || [ -z "$LAMBDA_URL" ]; then
      echo "❌ API_BASE_URL and LAMBDA_URL required for E2E tests"
      echo "Usage: $0 e2e <api_base_url> <lambda_url>"
      exit 1
    fi
    
    echo "🔄 Running E2E integration tests..."
    python tests/integration/test_e2e_flow.py "$API_BASE_URL" "$LAMBDA_URL"
    
    echo "🔌 Running API integration tests..."
    python tests/integration/test_api_integration.py "$API_BASE_URL"
    ;;
    
  "performance"|"load")
    if [ -z "$API_BASE_URL" ] || [ -z "$LAMBDA_URL" ]; then
      echo "❌ API_BASE_URL and LAMBDA_URL required for performance tests"
      echo "Usage: $0 performance <api_base_url> <lambda_url>"
      exit 1
    fi
    
    echo "⚡ Running performance tests..."
    python tests/performance/load_test.py "$API_BASE_URL" "$LAMBDA_URL" 100 10
    ;;
    
  "all")
    if [ -z "$API_BASE_URL" ] || [ -z "$LAMBDA_URL" ]; then
      echo "❌ Getting deployment URLs..."
      cd infrastructure/web-app
      API_BASE_URL="http://$(terraform output -raw alb_dns_name 2>/dev/null || echo 'localhost:8000')"
      cd ../..
      
      # Lambda URL은 기존 인프라에서 가져오기
      cd infrastructure
      LAMBDA_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo '')
      cd ..
      
      if [ -z "$LAMBDA_URL" ]; then
        echo "⚠️  Lambda URL not found. Skipping Lambda-dependent tests."
        echo "🔌 Running API-only tests..."
        python tests/integration/test_api_integration.py "$API_BASE_URL"
        exit 0
      fi
    fi
    
    echo "🔄 Running all integration tests..."
    python tests/integration/test_e2e_flow.py "$API_BASE_URL" "$LAMBDA_URL"
    python tests/integration/test_api_integration.py "$API_BASE_URL"
    
    echo "⚡ Running performance tests..."
    python tests/performance/load_test.py "$API_BASE_URL" "$LAMBDA_URL" 50 5
    ;;
    
  *)
    echo "Usage: $0 [e2e|performance|all] [api_base_url] [lambda_url]"
    echo ""
    echo "Test types:"
    echo "  e2e         - End-to-end integration tests"
    echo "  performance - Performance and load tests"
    echo "  all         - All tests (default)"
    echo ""
    echo "Examples:"
    echo "  $0 all"
    echo "  $0 e2e http://example.com https://api.example.com"
    echo "  $0 performance http://example.com https://api.example.com"
    exit 1
    ;;
esac

echo "✅ Phase 7 tests completed successfully!"