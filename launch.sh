#!/bin/bash

# CreditSentinel™ Production Launcher
# Enhanced with health checks, logging, and error handling

set -e  # Exit on any error

echo "🚀 Starting CreditSentinel™ Production Stack..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating from template..."
    cp .env.example .env
    echo "📝 Please edit .env with your production values before continuing."
    exit 1
fi

# Load environment variables
source .env

# Create logs directory
mkdir -p logs

# 1. Start Docker Backend (API + DB + Redis)
echo "📦 Starting production services..."
docker-compose up -d --build

# 2. Wait for all services to be healthy
echo "⏳ Waiting for services to be ready..."
RETRIES=30
SERVICES=("db" "redis" "creditsentinel")

for service in "${SERVICES[@]}"; do
    echo "   Checking $service..."
    retry_count=0
    while [ $retry_count -lt $RETRIES ]; do
        if docker-compose ps $service | grep -q "healthy\|Up"; then
            echo "   ✅ $service is ready"
            break
        fi
        if [ $retry_count -eq $((RETRIES-1)) ]; then
            echo "   ❌ $service failed to start. Check logs:"
            docker-compose logs $service
            exit 1
        fi
        echo "   ...waiting for $service ($((RETRIES-retry_count)) retries left)"
        sleep 5
        retry_count=$((retry_count+1))
    done
done

# 3. Run database migrations
echo "🔄 Running database migrations..."
docker-compose exec creditsentinel python -m alembic upgrade head

# 4. Health check
echo "🏥 Final health check..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ CreditSentinel™ is running at http://localhost:8000"
    echo "📊 View logs: docker-compose logs -f"
    echo "🛑 Stop services: docker-compose down"
else
    echo "❌ Health check failed. Check logs:"
    docker-compose logs creditsentinel
    exit 1
fi

# 5. Optional: Launch Frontend (if not using web build)
if [ "$1" = "--desktop" ]; then
    echo "🖥️  Launching Desktop UI..."
    cd frontend && flutter run -d linux
    
    # Cleanup on exit
    echo "🛑 Shutting down backend services..."
    cd ..
    docker-compose down
fi

echo "🎉 CreditSentinel™ is ready for production!"
