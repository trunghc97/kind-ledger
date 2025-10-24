#!/bin/bash

# KindLedger System Management Scripts
# Start script

set -e

echo "🚀 Starting KindLedger POC System..."

# Create data directories if they don't exist
echo "📁 Creating data directories..."
mkdir -p data/{postgres,redis,mongodb,ipfs,besu-validator,besu-observer}

# Set proper permissions
echo "🔐 Setting permissions..."
chmod -R 755 data/

# Start the system
echo "🐳 Starting Docker Compose..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service status
echo "📊 Checking service status..."
docker-compose ps

# Show logs for any failed services
echo "📝 Checking for any failed services..."
docker-compose ps --filter "status=exited" --format "table {{.Name}}\t{{.Status}}"

echo "✅ KindLedger POC System started successfully!"
echo ""
echo "🌐 Access URLs:"
echo "  Frontend: http://localhost:4200"
echo "  Gateway API: http://localhost:8080/api"
echo "  Blockchain Explorer: http://localhost:8088"
echo "  IPFS Gateway: http://localhost:8081"
echo ""
echo "📊 Monitor logs with: docker-compose logs -f"
echo "🛑 Stop system with: docker-compose down"
