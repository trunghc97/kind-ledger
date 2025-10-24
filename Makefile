# KindLedger POC Makefile
# Simplified commands for system management

.PHONY: help start stop restart clean health logs backup build

# Default target
help:
	@echo "KindLedger POC Management Commands"
	@echo "=================================="
	@echo ""
	@echo "System Management:"
	@echo "  make start     - Start the entire system"
	@echo "  make stop      - Stop the entire system"
	@echo "  make restart   - Restart the entire system"
	@echo "  make clean     - Clean all data and containers"
	@echo ""
	@echo "Monitoring:"
	@echo "  make health    - Check system health"
	@echo "  make logs      - Show logs for all services"
	@echo "  make logs-f    - Follow logs in real-time"
	@echo ""
	@echo "Data Management:"
	@echo "  make backup    - Create system backup"
	@echo "  make restore   - Restore from backup"
	@echo ""
	@echo "Development:"
	@echo "  make build     - Build all Docker images"
	@echo "  make dev       - Start in development mode"
	@echo ""

# System management
start:
	@echo "🚀 Starting KindLedger POC System..."
	@./scripts/start.sh

stop:
	@echo "🛑 Stopping KindLedger POC System..."
	@./scripts/stop.sh

restart:
	@echo "🔄 Restarting KindLedger POC System..."
	@./scripts/restart.sh

clean:
	@echo "🧹 Cleaning KindLedger POC System..."
	@./scripts/clean.sh

# Monitoring
health:
	@echo "🏥 Checking system health..."
	@./scripts/health.sh

logs:
	@echo "📝 Showing system logs..."
	@./scripts/logs.sh

logs-f:
	@echo "📝 Following system logs..."
	@./scripts/logs.sh -f

# Data management
backup:
	@echo "💾 Creating system backup..."
	@./scripts/backup.sh

# Development
build:
	@echo "🔨 Building Docker images..."
	@docker-compose build

dev:
	@echo "🛠️  Starting in development mode..."
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Service-specific commands
restart-gateway:
	@echo "🔄 Restarting gateway service..."
	@./scripts/restart.sh -s gateway

restart-frontend:
	@echo "🔄 Restarting frontend service..."
	@./scripts/restart.sh -s frontend

logs-gateway:
	@echo "📝 Showing gateway logs..."
	@./scripts/logs.sh -s gateway

logs-frontend:
	@echo "📝 Showing frontend logs..."
	@./scripts/logs.sh -s frontend

# Database commands
db-backup:
	@echo "🗄️  Creating database backup..."
	@./sql/backup/backup.sh

db-restore:
	@echo "🗄️  Restoring database..."
	@./sql/backup/restore.sh

# Status commands
status:
	@echo "📊 System Status:"
	@docker-compose ps

services:
	@echo "🔍 Available services:"
	@echo "  postgres, redis, mongodb, ipfs"
	@echo "  besu-validator, besu-observer"
	@echo "  gateway, frontend, explorer"

# Quick start for new users
quick-start: start health
	@echo ""
	@echo "✅ KindLedger POC is ready!"
	@echo ""
	@echo "🌐 Access URLs:"
	@echo "  Frontend: http://localhost:4200"
	@echo "  Gateway API: http://localhost:8080/api"
	@echo "  Blockchain Explorer: http://localhost:8088"
	@echo "  IPFS Gateway: http://localhost:8081"
	@echo ""
	@echo "📊 Monitor with: make health"
	@echo "📝 View logs with: make logs"
