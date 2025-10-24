#!/bin/bash

# KindLedger System Restart Script

set -e

SERVICE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --service SERVICE    Restart specific service"
            echo "  -h, --help               Show this help message"
            echo ""
            echo "Available services:"
            echo "  postgres, redis, mongodb, ipfs, besu-validator, besu-observer, gateway, frontend, explorer"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Restart all services"
            echo "  $0 -s gateway                          # Restart only gateway service"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "🔄 KindLedger System Restart"
echo "============================"

if [ -n "$SERVICE" ]; then
    echo "🔄 Restarting service: $SERVICE"
    echo "--------------------------------"
    
    # Stop the service
    echo "⏹️  Stopping $SERVICE..."
    docker-compose stop "$SERVICE"
    
    # Start the service
    echo "▶️  Starting $SERVICE..."
    docker-compose start "$SERVICE"
    
    # Wait for service to be healthy
    echo "⏳ Waiting for $SERVICE to be healthy..."
    sleep 10
    
    # Check if service is running
    if docker ps --filter "name=kindledger-$SERVICE" --filter "status=running" | grep -q "kindledger-$SERVICE"; then
        echo "✅ $SERVICE restarted successfully!"
    else
        echo "❌ $SERVICE failed to start!"
        exit 1
    fi
else
    echo "🔄 Restarting all services"
    echo "-------------------------"
    
    # Stop all services
    echo "⏹️  Stopping all services..."
    docker-compose stop
    
    # Start all services
    echo "▶️  Starting all services..."
    docker-compose start
    
    # Wait for services to be healthy
    echo "⏳ Waiting for services to be healthy..."
    sleep 30
    
    # Check service status
    echo "📊 Checking service status..."
    docker-compose ps
    
    echo "✅ All services restarted successfully!"
fi

echo ""
echo "🌐 Access URLs:"
echo "  Frontend: http://localhost:4200"
echo "  Gateway API: http://localhost:8080/api"
echo "  Blockchain Explorer: http://localhost:8088"
echo "  IPFS Gateway: http://localhost:8081"
