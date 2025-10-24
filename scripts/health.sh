#!/bin/bash

# KindLedger System Health Check Script

set -e

echo "🏥 KindLedger System Health Check"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service health
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Checking $service_name... "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✓ Healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ Unhealthy${NC}"
        return 1
    fi
}

# Function to check container status
check_container() {
    local container_name=$1
    
    echo -n "Checking container $container_name... "
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

# Function to check database connectivity
check_database() {
    echo -n "Checking PostgreSQL... "
    
    if docker exec kindledger-postgres pg_isready -U postgres -d kindledger > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Function to check Redis connectivity
check_redis() {
    echo -n "Checking Redis... "
    
    if docker exec kindledger-redis redis-cli ping | grep -q "PONG"; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Function to check MongoDB connectivity
check_mongodb() {
    echo -n "Checking MongoDB... "
    
    if docker exec kindledger-mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Function to check blockchain connectivity
check_blockchain() {
    echo -n "Checking Besu Validator... "
    
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | grep -q "result"; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Function to check IPFS connectivity
check_ipfs() {
    echo -n "Checking IPFS... "
    
    if curl -s http://localhost:5001/api/v0/id > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Main health check
echo "🔍 Checking containers..."
echo "------------------------"

# Check all containers
check_container "kindledger-postgres"
check_container "kindledger-redis"
check_container "kindledger-mongodb"
check_container "kindledger-ipfs"
check_container "kindledger-besu-validator"
check_container "kindledger-besu-observer"
check_container "kindledger-gateway"
check_container "kindledger-frontend"
check_container "kindledger-explorer"

echo ""
echo "🔍 Checking services..."
echo "----------------------"

# Check service endpoints
check_service "Frontend" "http://localhost:4200"
check_service "Gateway API" "http://localhost:8080/actuator/health"
check_service "Blockchain Explorer" "http://localhost:8088/api/health"
check_service "IPFS Gateway" "http://localhost:8081"

echo ""
echo "🔍 Checking databases..."
echo "-----------------------"

# Check database connections
check_database
check_redis
check_mongodb

echo ""
echo "🔍 Checking blockchain..."
echo "-------------------------"

# Check blockchain connectivity
check_blockchain
check_ipfs

echo ""
echo "📊 System Summary"
echo "=================="

# Count healthy services
total_services=9
healthy_services=0

# Re-run checks to count healthy services
for service in "kindledger-postgres" "kindledger-redis" "kindledger-mongodb" "kindledger-ipfs" "kindledger-besu-validator" "kindledger-besu-observer" "kindledger-gateway" "kindledger-frontend" "kindledger-explorer"; do
    if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
        ((healthy_services++))
    fi
done

echo "Healthy services: $healthy_services/$total_services"

if [ $healthy_services -eq $total_services ]; then
    echo -e "${GREEN}🎉 All services are healthy!${NC}"
    exit 0
elif [ $healthy_services -gt $((total_services / 2)) ]; then
    echo -e "${YELLOW}⚠️  Some services are unhealthy${NC}"
    exit 1
else
    echo -e "${RED}❌ Multiple services are unhealthy${NC}"
    exit 2
fi
