#!/bin/bash

# Kind-Ledger Gateway API Test Script
# This script tests all API endpoints of the Kind-Ledger gateway

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:8080"
GATEWAY_PORT=8080

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kind-Ledger Gateway API Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python3 is not installed${NC}"
    exit 1
fi

# Check if requests module is available
if ! python3 -c "import requests" 2>/dev/null; then
    echo -e "${YELLOW}Installing requests module...${NC}"
    pip3 install requests
fi

# Check if gateway is running
echo -e "${YELLOW}Checking if gateway is accessible...${NC}"
if curl -s -f "${BASE_URL}/api/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Gateway is running on port ${GATEWAY_PORT}${NC}\n"
else
    echo -e "${RED}✗ Gateway is not accessible on port ${GATEWAY_PORT}${NC}"
    echo -e "${YELLOW}Please start the gateway service:${NC}"
    echo -e "  docker-compose up -d gateway"
    exit 1
fi

# Run the Python test script
echo -e "${BLUE}Running test suite...${NC}\n"
python3 test_gateway_api.py

TEST_EXIT_CODE=$?

echo -e "\n${BLUE}========================================${NC}"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}All tests completed successfully!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed or returned unexpected results${NC}"
    exit $TEST_EXIT_CODE
fi
