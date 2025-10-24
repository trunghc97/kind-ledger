#!/bin/bash

# KindLedger System Management Scripts
# Clean script - WARNING: This will remove all data!

set -e

echo "⚠️  WARNING: This will remove ALL data including databases, blockchain data, and IPFS content!"
echo "Are you sure you want to continue? (yes/no)"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
    echo "❌ Operation cancelled."
    exit 1
fi

echo "🧹 Cleaning KindLedger POC System..."

# Stop all services
echo "🛑 Stopping services..."
docker-compose down

# Remove containers, networks, and volumes
echo "🗑️  Removing containers and volumes..."
docker-compose down -v --remove-orphans

# Remove data directories
echo "📁 Removing data directories..."
rm -rf data/

# Remove Docker images (optional)
echo "🖼️  Removing Docker images..."
docker-compose down --rmi all --remove-orphans

# Clean up unused Docker resources
echo "🧽 Cleaning up Docker resources..."
docker system prune -f

echo "✅ KindLedger POC System cleaned successfully!"
echo ""
echo "🚀 To start fresh: ./scripts/start.sh"
