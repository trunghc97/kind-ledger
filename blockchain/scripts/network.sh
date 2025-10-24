#!/bin/bash

# Kind-Ledger Network Management Script
# Quản lý mạng Fabric (up/down)

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Thư mục gốc
ROOT_DIR=$(pwd)
BLOCKCHAIN_DIR="$ROOT_DIR/blockchain"

echo -e "${GREEN}🌐 Kind-Ledger Network Management${NC}"
echo "=================================="

# Kiểm tra docker và docker-compose
check_docker() {
    echo -e "${YELLOW}📋 Kiểm tra Docker...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker không được tìm thấy. Vui lòng cài đặt Docker.${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose không được tìm thấy. Vui lòng cài đặt Docker Compose.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker và Docker Compose đã sẵn sàng${NC}"
}

# Khởi động mạng
start_network() {
    echo -e "${YELLOW}🚀 Khởi động mạng Kind-Ledger...${NC}"
    
    cd "$ROOT_DIR"
    
    # Kiểm tra xem crypto materials đã được tạo chưa
    if [ ! -d "$BLOCKCHAIN_DIR/crypto-config" ]; then
        echo -e "${RED}❌ Crypto materials chưa được tạo. Vui lòng chạy ./generate.sh trước.${NC}"
        exit 1
    fi
    
    # Khởi động các container
    docker-compose up -d
    
    echo -e "${GREEN}✅ Mạng đã được khởi động${NC}"
    echo -e "${YELLOW}⏳ Đang chờ các container khởi động hoàn tất...${NC}"
    
    # Chờ các container khởi động
    sleep 30
    
    # Kiểm tra trạng thái các container
    echo -e "${YELLOW}📊 Trạng thái các container:${NC}"
    docker-compose ps
    
    echo -e "${GREEN}🎉 Mạng Kind-Ledger đã sẵn sàng!${NC}"
}

# Dừng mạng
stop_network() {
    echo -e "${YELLOW}🛑 Dừng mạng Kind-Ledger...${NC}"
    
    cd "$ROOT_DIR"
    
    docker-compose down
    
    echo -e "${GREEN}✅ Mạng đã được dừng${NC}"
}

# Restart mạng
restart_network() {
    echo -e "${YELLOW}🔄 Khởi động lại mạng Kind-Ledger...${NC}"
    
    stop_network
    sleep 5
    start_network
}

# Xóa tất cả (bao gồm volumes)
clean_network() {
    echo -e "${YELLOW}🧹 Xóa tất cả dữ liệu mạng...${NC}"
    
    cd "$ROOT_DIR"
    
    docker-compose down -v
    docker system prune -f
    
    echo -e "${GREEN}✅ Dữ liệu mạng đã được xóa${NC}"
}

# Kiểm tra logs
show_logs() {
    echo -e "${YELLOW}📋 Hiển thị logs...${NC}"
    
    cd "$ROOT_DIR"
    
    if [ -n "$1" ]; then
        docker-compose logs -f "$1"
    else
        docker-compose logs -f
    fi
}

# Kiểm tra trạng thái
show_status() {
    echo -e "${YELLOW}📊 Trạng thái mạng:${NC}"
    
    cd "$ROOT_DIR"
    
    docker-compose ps
    
    echo -e "\n${YELLOW}🔍 Kiểm tra kết nối:${NC}"
    
    # Kiểm tra orderer
    if curl -s http://localhost:7050 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Orderer: OK${NC}"
    else
        echo -e "${RED}❌ Orderer: Không kết nối được${NC}"
    fi
    
    # Kiểm tra các peer
    for port in 7051 8051 9051 10051; do
        if curl -s http://localhost:$port > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Peer port $port: OK${NC}"
        else
            echo -e "${RED}❌ Peer port $port: Không kết nối được${NC}"
        fi
    done
}

# Hiển thị help
show_help() {
    echo -e "${GREEN}Kind-Ledger Network Management Script${NC}"
    echo "=================================="
    echo ""
    echo "Sử dụng: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up       - Khởi động mạng"
    echo "  down     - Dừng mạng"
    echo "  restart  - Khởi động lại mạng"
    echo "  clean    - Xóa tất cả dữ liệu"
    echo "  logs     - Hiển thị logs (có thể chỉ định service)"
    echo "  status   - Kiểm tra trạng thái"
    echo "  help     - Hiển thị help này"
    echo ""
    echo "Ví dụ:"
    echo "  $0 up                    # Khởi động mạng"
    echo "  $0 logs orderer          # Xem logs của orderer"
    echo "  $0 status                # Kiểm tra trạng thái"
}

# Main function
main() {
    case "${1:-help}" in
        up)
            check_docker
            start_network
            ;;
        down)
            stop_network
            ;;
        restart)
            check_docker
            restart_network
            ;;
        clean)
            clean_network
            ;;
        logs)
            show_logs "$2"
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Command không hợp lệ: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Chạy script
main "$@"
