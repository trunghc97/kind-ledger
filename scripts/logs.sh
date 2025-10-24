#!/bin/bash

# KindLedger System Logs Script

set -e

# Default values
SERVICE=""
LINES=100
FOLLOW=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --service SERVICE    Show logs for specific service"
            echo "  -n, --lines LINES        Number of lines to show (default: 100)"
            echo "  -f, --follow             Follow logs in real-time"
            echo "  -h, --help               Show this help message"
            echo ""
            echo "Available services:"
            echo "  postgres, redis, mongodb, ipfs, besu-validator, besu-observer, gateway, frontend, explorer"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Show logs for all services"
            echo "  $0 -s gateway -f                      # Follow gateway logs"
            echo "  $0 -s postgres -n 50                  # Show last 50 lines of postgres logs"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "📝 KindLedger System Logs"
echo "========================="

if [ -n "$SERVICE" ]; then
    echo "📋 Showing logs for service: $SERVICE"
    echo "----------------------------------------"
    
    if [ "$FOLLOW" = true ]; then
        echo "🔄 Following logs (Press Ctrl+C to stop)..."
        docker-compose logs -f --tail="$LINES" "$SERVICE"
    else
        docker-compose logs --tail="$LINES" "$SERVICE"
    fi
else
    echo "📋 Showing logs for all services"
    echo "--------------------------------"
    
    if [ "$FOLLOW" = true ]; then
        echo "🔄 Following logs (Press Ctrl+C to stop)..."
        docker-compose logs -f --tail="$LINES"
    else
        docker-compose logs --tail="$LINES"
    fi
fi
