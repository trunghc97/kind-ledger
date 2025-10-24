#!/bin/bash

# KindLedger System Management Scripts
# Stop script

set -e

echo "🛑 Stopping KindLedger POC System..."

# Stop all services
docker-compose down

echo "✅ KindLedger POC System stopped successfully!"
echo ""
echo "💾 Data is preserved in ./data/ directory"
echo "🔄 To start again: ./scripts/start.sh"
echo "🗑️  To remove all data: ./scripts/clean.sh"
