#!/bin/bash
set -e

MODE=${1:-native}

case $MODE in
  "native"|"n")
    echo "🚀 Starting Django development server (native)..."
    cd src
    export DEBUG=True
    export AWS_DEFAULT_REGION=us-east-1
    export EVENTS_TABLE=LiveInsight-Events
    export SESSIONS_TABLE=LiveInsight-Sessions
    export ACTIVE_SESSIONS_TABLE=LiveInsight-ActiveSessions
    
    echo "🌐 Server will be available at http://localhost:8000"
    python manage.py runserver 0.0.0.0:8000
    ;;
    
  "docker"|"d")
    echo "🐳 Starting Django development with Docker..."
    cd src
    echo "🚀 Starting services with Docker Compose..."
    docker-compose up --build
    ;;
    
  *)
    echo "Usage: $0 [native|docker]"
    echo "  native (n) - Run Django natively"
    echo "  docker (d) - Run with Docker Compose"
    exit 1
    ;;
esac