#!/bin/bash
set -e

TYPE=${1:-local}

case $TYPE in
  "local"|"l")
    echo "🧪 Testing Django application locally..."
    if [ ! -d "src" ]; then
        echo "❌ src directory not found"
        exit 1
    fi
    
    cd src
    echo "🔧 Checking Django configuration..."
    python manage.py check
    
    echo "📋 Checking migrations..."
    python manage.py makemigrations --dry-run --check
    
    echo "📦 Testing static file collection..."
    python manage.py collectstatic --noinput --dry-run
    
    echo "✅ All local tests passed!"
    cd ..
    ;;
    
  "deployment"|"d")
    echo "🧪 Testing deployment..."
    cd infrastructure/web-app
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
    
    if [ -z "$ALB_DNS" ]; then
        echo "❌ No deployment found. Please deploy first."
        exit 1
    fi
    
    BASE_URL="http://$ALB_DNS"
    cd ../..
    
    echo "🌐 Testing URL: $BASE_URL"
    
    echo "🏥 Testing health endpoint..."
    if curl -f "$BASE_URL/health/" > /dev/null 2>&1; then
        echo "✅ Health check passed"
    else
        echo "❌ Health check failed"
        exit 1
    fi
    
    echo "📊 Testing dashboard endpoint..."
    if curl -f "$BASE_URL/" > /dev/null 2>&1; then
        echo "✅ Dashboard accessible"
    else
        echo "❌ Dashboard not accessible"
        exit 1
    fi
    
    echo "✅ All deployment tests passed!"
    ;;
    
  *)
    echo "Usage: $0 [local|deployment]"
    echo "  local (l)      - Test Django application locally"
    echo "  deployment (d) - Test deployed application"
    exit 1
    ;;
esac