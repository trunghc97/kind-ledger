#!/bin/bash

# Kind-Ledger Build Cache Script
# Build và cache các Docker images để tăng tốc độ build sau này

echo "🔨 Building and caching Docker images..."

# Build và tag images để cache
echo "Building Gateway image..."
docker build -t kindledger-gateway:latest ./gateway

echo "Building Frontend image..."
docker build -t kindledger-frontend:latest ./frontend

echo "Building Explorer image..."
docker build -t kindledger-explorer:latest ./explorer

echo "✅ All images built and cached successfully!"
echo "Now you can run: docker-compose up --build -d"
