# Kind-Ledger POC - Quick Start Guide

## 🚀 Chạy Hệ Thống Hoàn Chỉnh

### Yêu cầu hệ thống
- Docker và Docker Compose
- 8GB RAM trở lên
- 20GB dung lượng trống

### Cách chạy nhanh

```bash
# 1. Setup thư mục cần thiết
./setup.sh

# 2. Build và cache images (lần đầu hoặc khi có thay đổi)
./build-cache.sh

# 3. Chạy hệ thống
docker-compose up --build -d
```

### Tối ưu caching

```bash
# Build cache trước (chỉ cần làm 1 lần)
./build-cache.sh

# Sau đó chỉ cần chạy
docker-compose up -d
```

### Kiểm tra trạng thái

```bash
# Xem trạng thái tất cả services
docker-compose ps

# Kiểm tra logs
docker-compose logs -f

# Kiểm tra logs của service cụ thể
docker-compose logs -f gateway
docker-compose logs -f frontend
docker-compose logs -f explorer
```

## 📊 Các Service và Ports

| Service | URL | Port | Mô tả |
|---------|-----|------|-------|
| **Gateway API** | http://localhost:8080 | 8080 | Spring Boot REST API |
| **Frontend UI** | http://localhost:4200 | 4200 | Angular Web Interface |
| **Explorer** | http://localhost:3000 | 3000 | Blockchain Explorer |
| **PostgreSQL** | localhost:5432 | 5432 | Relational Database |
| **MongoDB** | localhost:27017 | 27017 | Document Database |
| **Redis** | localhost:6379 | 6379 | Cache & Session Store |

## 🔗 Hyperledger Fabric Network

| Component | Port | Mô tả |
|-----------|------|-------|
| **Orderer** | 7050 | Raft Consensus Orderer |
| **MB Bank Peer** | 7051 | Ngân hàng phát hành token |
| **Charity Peer** | 8051 | Tổ chức từ thiện |
| **Supplier Peer** | 9051 | Nhà cung cấp |
| **Auditor Peer** | 10051 | Node giám sát |

## 🛠️ Các Lệnh Hữu Ích

### Quản lý hệ thống
```bash
# Dừng tất cả services
docker-compose down

# Khởi động lại
docker-compose restart

# Xem logs real-time
docker-compose logs -f

# Dọn dẹp (xóa containers và volumes)
docker-compose down -v
docker system prune -a
```

### Kiểm tra sức khỏe
```bash
# Kiểm tra Gateway API
curl http://localhost:8080/actuator/health

# Kiểm tra Frontend
curl http://localhost:4200

# Kiểm tra Explorer
curl http://localhost:3000
```

### Truy cập Database
```bash
# PostgreSQL
docker exec -it kindledger-postgres psql -U kindledger -d kindledger

# MongoDB
docker exec -it kindledger-mongodb mongosh -u kindledger -p kindledger123

# Redis
docker exec -it kindledger-redis redis-cli -a kindledger123
```

## 🔧 Cấu Hình

### Environment Variables
Tất cả cấu hình được định nghĩa trong `docker-compose.yml`:

- **Database**: PostgreSQL, MongoDB, Redis
- **Fabric**: 4 organizations với Raft consensus
- **Applications**: Spring Boot Gateway, Angular Frontend, Node.js Explorer

### Volumes
- `postgres_data`: Dữ liệu PostgreSQL
- `mongodb_data`: Dữ liệu MongoDB  
- `redis_data`: Dữ liệu Redis
- `*_peer_data`: Dữ liệu Fabric peers

## 🐛 Troubleshooting

### Lỗi thường gặp

1. **Port đã được sử dụng**
   ```bash
   # Kiểm tra port nào đang được sử dụng
   lsof -i :8080
   # Dừng service đang sử dụng port
   ```

2. **Out of memory**
   ```bash
   # Tăng memory cho Docker
   # Docker Desktop > Settings > Resources > Memory
   ```

3. **Container không start**
   ```bash
   # Xem logs chi tiết
   docker-compose logs [service_name]
   ```

### Reset hoàn toàn
```bash
# Dừng và xóa tất cả
docker-compose down -v
docker system prune -a

# Chạy lại
./setup.sh
docker-compose up --build -d
```

## 📝 API Endpoints

### Gateway API (http://localhost:8080)

```
GET  /api/campaigns          # Lấy danh sách campaigns
POST /api/campaigns          # Tạo campaign mới
GET  /api/campaigns/{id}     # Lấy chi tiết campaign
POST /api/donate             # Quyên góp
GET  /api/health             # Health check
```

### Explorer API (http://localhost:3000)

```
GET  /api/blocks             # Lấy danh sách blocks
GET  /api/transactions       # Lấy danh sách transactions
GET  /api/peers              # Lấy thông tin peers
```

## 🎯 Tính Năng Chính

- ✅ **Hyperledger Fabric Network** với 4 organizations
- ✅ **Raft Consensus** cho orderer
- ✅ **Go Chaincode** cho smart contracts
- ✅ **Spring Boot Gateway** với REST API
- ✅ **Angular Frontend** với responsive UI
- ✅ **Node.js Explorer** cho blockchain monitoring
- ✅ **Multi-database** (PostgreSQL, MongoDB, Redis)
- ✅ **Docker Compose** orchestration
- ✅ **Health checks** và monitoring
- ✅ **Persistent volumes** cho data

## 📞 Hỗ Trợ

Nếu gặp vấn đề, hãy kiểm tra:
1. Docker và Docker Compose đã cài đặt
2. Ports 3000, 4200, 8080, 5432, 6379, 7050-10051 không bị chiếm
3. Đủ RAM (8GB+) và dung lượng (20GB+)
4. Logs của services để xem lỗi cụ thể

---

**Kind-Ledger POC** - Complete Blockchain Charity Platform