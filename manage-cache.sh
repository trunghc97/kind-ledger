#!/bin/bash

# Kind-Ledger Cache Management Script

case "$1" in
    "build")
        echo "🔨 Building and caching images..."
        ./build-cache.sh
        ;;
    "clean")
        echo "🧹 Cleaning Docker cache..."
        docker system prune -f
        docker builder prune -f
        ;;
    "images")
        echo "📦 Listing cached images..."
        docker images | grep kindledger
        ;;
    "size")
        echo "📊 Docker system size:"
        docker system df
        ;;
    "help")
        echo "Kind-Ledger Cache Management"
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  build   - Build and cache all images"
        echo "  clean   - Clean Docker cache and build cache"
        echo "  images  - List cached images"
        echo "  size    - Show Docker system size"
        echo "  help    - Show this help"
        ;;
    *)
        echo "Usage: $0 {build|clean|images|size|help}"
        exit 1
        ;;
esac
