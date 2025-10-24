# KindLedger POC - Nền tảng thiện nguyện minh bạch

KindLedger là nền tảng thiện nguyện sử dụng blockchain để đảm bảo tính minh bạch và truy xuất nguồn gốc của các giao dịch thiện nguyện.

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Gateway       │    │   Blockchain    │
│   Angular 17    │◄──►│   Spring Boot   │◄──►│   Hyperledger   │
│   Port: 4200    │    │   Port: 8080    │    │   Besu          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   IPFS          │    │   PostgreSQL    │    │   Redis         │
│   Storage       │    │   Database      │    │   Cache         │
│   Port: 5001    │    │   Port: 5432   │    │   Port: 6379    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Triển khai nhanh

### Yêu cầu hệ thống
- Docker & Docker Compose
- 8GB RAM trở lên
- 20GB dung lượng trống
- Ports: 4200, 8080, 5432, 6379, 27017, 5001, 8081, 8545, 30303

### Chạy hệ thống

```bash
# Clone repository
git clone <repository-url>
cd kind-ledger

# Khởi động toàn bộ hệ thống
docker-compose up -d

# Kiểm tra trạng thái
docker-compose ps

# Kiểm tra health của các service
curl http://localhost:8080/actuator/health
curl http://localhost:4200
```

### ✅ Trạng thái hệ thống hiện tại

| Service | Port | Status | Mô tả |
|---------|------|--------|-------|
| Gateway API | 8080 | ✅ Healthy | Backend Spring Boot sẵn sàng |
| Frontend | 4200 | ⏳ Starting | Angular app đang khởi động |
| PostgreSQL | 5432 | ✅ Healthy | Database chính |
| MongoDB | 27017 | ✅ Healthy | Database phụ |
| Redis | 6379 | ✅ Healthy | Cache và session store |
| Besu Validator | 8545 | ✅ Running | Blockchain node |
| IPFS | 5001 | ⚠️ Restarting | File storage |
| Explorer | 8088 | ⚠️ Restarting | Block explorer |

### Quản lý hệ thống

```bash
# Khởi động hệ thống
./scripts/start.sh

# Dừng hệ thống
./scripts/stop.sh

# Restart hệ thống
./scripts/restart.sh

# Restart service cụ thể
./scripts/restart.sh -s gateway

# Xem logs
./scripts/logs.sh

# Xem logs service cụ thể
./scripts/logs.sh -s gateway -f

# Kiểm tra sức khỏe hệ thống
./scripts/health.sh

# Backup dữ liệu
./scripts/backup.sh

# Dọn dẹp hoàn toàn (XÓA TẤT CẢ DỮ LIỆU)
./scripts/clean.sh
```

### Truy cập các dịch vụ

| Dịch vụ | URL | Mô tả | Trạng thái |
|---------|-----|-------|------------|
| Frontend | http://localhost:4200 | Giao diện người dùng | ⏳ Đang khởi động |
| Gateway API | http://localhost:8080/api | API backend | ✅ Sẵn sàng |
| Gateway Health | http://localhost:8080/actuator/health | Health check | ✅ Healthy |
| Blockchain RPC | http://localhost:8545 | Blockchain API | ✅ Hoạt động |
| PostgreSQL | localhost:5432 | Database chính | ✅ Healthy |
| MongoDB | localhost:27017 | Database phụ | ✅ Healthy |
| Redis | localhost:6379 | Cache | ✅ Healthy |
| IPFS Gateway | http://localhost:8081 | Lưu trữ file | ⚠️ Đang khởi động |
| Blockchain Explorer | http://localhost:8088 | Khám phá blockchain | ⚠️ Đang khởi động |

## 🎯 Trạng thái hệ thống hiện tại

### ✅ **Đã hoạt động ổn định:**
- **Gateway API** (Port 8080) - Backend Spring Boot với tất cả dependencies
- **PostgreSQL** (Port 5432) - Database chính với schema đã được khởi tạo
- **MongoDB** (Port 27017) - Database phụ cho document storage
- **Redis** (Port 6379) - Cache và session store
- **Besu Validator** (Port 8545) - Blockchain node với ethash consensus

### ⏳ **Đang khởi động:**
- **Frontend** (Port 4200) - Angular app đang khởi động
- **IPFS** (Port 5001) - File storage system
- **Explorer** (Port 8088) - Block explorer

### 🔧 **Các lỗi đã được sửa:**
1. ✅ Xung đột port 8080 và 4200 với containers khác
2. ✅ Java version mismatch trong Gateway Dockerfile
3. ✅ PostgreSQL schema validation (SERIAL → BIGSERIAL)
4. ✅ Spring Cloud compatibility issues
5. ✅ Redis connection configuration
6. ✅ Besu genesis block configuration
7. ✅ Dockerfile user creation issues

### 🚀 **Hệ thống sẵn sàng sử dụng:**
- API Gateway đã hoạt động: `http://localhost:8080/api/campaigns`
- Health check: `http://localhost:8080/actuator/health`
- Blockchain RPC: `http://localhost:8545`

## 📋 Chức năng chính

### 🔗 Kết nối ví MetaMask
- Kết nối ví Ethereum
- Chuyển đổi mạng sang KindLedger Network
- Hiển thị số dư cVND

### 💰 Quản lý token cVND
- **Nạp tiền**: Chuyển VND từ tài khoản ngân hàng thành cVND
- **Rút tiền**: Chuyển cVND thành VND
- **Ủng hộ**: Donate cVND vào các chiến dịch
- **Mua vật phẩm**: Mua vật phẩm ủng hộ bằng cVND

### 🎯 Chiến dịch thiện nguyện
- Tạo và quản lý chiến dịch
- Theo dõi tiến độ ủng hộ
- Lưu trữ chứng từ minh bạch trên IPFS
- Truy xuất nguồn gốc giao dịch

### 🔍 Blockchain Explorer
- Xem các block và transaction
- Tra cứu địa chỉ ví
- Theo dõi trạng thái mạng

## 🛠️ Cấu trúc dự án

```
kind-ledger/
├── docker-compose.yml          # Cấu hình Docker Compose
├── README.md                   # Tài liệu dự án
├── blockchain/
│   └── genesis.json            # Cấu hình blockchain
├── gateway/                    # Spring Boot Backend
│   ├── src/main/java/...       # Mã nguồn Java
│   ├── pom.xml                 # Maven dependencies
│   └── Dockerfile              # Docker image
├── frontend/                   # Angular Frontend
│   ├── src/app/...             # Mã nguồn Angular
│   ├── package.json            # Node dependencies
│   └── Dockerfile              # Docker image
├── explorer/                   # Blockchain Explorer
│   ├── server.js               # Express server
│   └── Dockerfile              # Docker image
└── sql/
    └── init.sql                # Database schema
```

## 🔧 Cấu hình môi trường

### Biến môi trường

```bash
# Database
POSTGRES_URL=jdbc:postgresql://postgres:5432/kindledger
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Redis
REDIS_URL=redis://redis:6379

# MongoDB
MONGODB_URL=mongodb://admin:password@mongodb:27017/kindledger

# IPFS
IPFS_URL=http://ipfs:5001

# Blockchain
BESU_VALIDATOR_URL=http://besu-validator:8545
```

## 📊 API Endpoints

### Campaign APIs
- `GET /api/campaigns` - Lấy danh sách chiến dịch
- `GET /api/campaigns/active` - Lấy chiến dịch đang hoạt động
- `GET /api/campaigns/{id}` - Lấy chi tiết chiến dịch
- `POST /api/donate` - Ủng hộ chiến dịch

### Transaction APIs
- `POST /api/mint` - Nạp tiền vào ví
- `POST /api/burn` - Rút tiền từ ví
- `POST /api/redeem` - Đổi token
- `GET /api/wallet/{address}/balance` - Lấy số dư ví
- `GET /api/wallet/{address}/transactions` - Lấy lịch sử giao dịch

### Utility APIs
- `POST /api/kyc/check` - Kiểm tra KYC

## 🔒 Bảo mật

### AML/KYC Integration
- Kiểm tra giao dịch ẩn danh > 10M VND
- Xác thực danh tính người dùng
- Giám sát giao dịch đáng ngờ

### Smart Contract Security
- Sử dụng IBFT/PoA consensus
- Validator nodes được kiểm soát
- Audit trail đầy đủ

## 🚨 Xử lý sự cố

### Kiểm tra trạng thái hệ thống
```bash
# Xem trạng thái tất cả containers
docker-compose ps

# Kiểm tra health của Gateway
curl http://localhost:8080/actuator/health

# Test API Gateway
curl http://localhost:8080/api/campaigns
```

### Kiểm tra logs
```bash
# Xem logs của tất cả services
docker-compose logs

# Xem logs của service cụ thể
docker-compose logs gateway
docker-compose logs frontend
docker-compose logs besu-validator
```

### Restart services
```bash
# Restart tất cả
docker-compose restart

# Restart service cụ thể
docker-compose restart gateway
docker-compose restart frontend
```

### Xử lý lỗi thường gặp

#### Port conflicts
```bash
# Kiểm tra port đang được sử dụng
lsof -i :8080
lsof -i :4200

# Dừng container xung đột
docker stop <container-name>
```

#### Database issues
```bash
# Reset database
docker-compose down -v
docker-compose up -d

# Hoặc chỉ restart database
docker-compose restart postgres
```

#### Blockchain issues
```bash
# Restart Besu validator
docker-compose restart besu-validator

# Kiểm tra logs blockchain
docker-compose logs besu-validator
```

## 📈 Monitoring

### Health Checks
- **Gateway**: http://localhost:8080/actuator/health ✅
- **Frontend**: http://localhost:4200 ⏳
- **Blockchain RPC**: http://localhost:8545 ✅
- **PostgreSQL**: localhost:5432 ✅
- **MongoDB**: localhost:27017 ✅
- **Redis**: localhost:6379 ✅

### Metrics
- JVM metrics qua Spring Boot Actuator
- Database connection pool status
- Redis cache hit rate
- Blockchain node status

### Kiểm tra nhanh
```bash
# Kiểm tra tất cả services
docker-compose ps

# Test API endpoints
curl -s http://localhost:8080/actuator/health | jq .
curl -s http://localhost:8080/api/campaigns | jq .

# Test blockchain
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

## 🔄 Backup & Recovery

### Tự động Backup
```bash
# Tạo backup toàn bộ hệ thống
./scripts/backup.sh

# Backup sẽ được lưu trong thư mục backups/
```

### Database Backup thủ công
```bash
# Backup PostgreSQL
docker-compose exec postgres pg_dump -U postgres kindledger > backup.sql

# Restore từ backup
./sql/backup/restore.sh backup.sql

# Hoặc restore từ file nén
./sql/backup/restore.sh backup.sql.gz
```

### IPFS Data
```bash
# Backup IPFS data
docker cp kindledger-ipfs:/data/ipfs ./ipfs-backup

# Restore IPFS data
docker cp ./ipfs-backup kindledger-ipfs:/data/ipfs
```

### Persistent Data
Tất cả dữ liệu được lưu trữ trong Docker volumes:
- `postgres_data` - PostgreSQL database
- `redis_data` - Redis cache  
- `mongodb_data` - MongoDB documents
- `ipfs_data` - IPFS storage
- `besu_validator_data` - Blockchain validator data

### Kiểm tra volumes
```bash
# Xem tất cả volumes
docker volume ls | grep kindledger

# Xem chi tiết volume
docker volume inspect kindledger_postgres_data
```

## 📝 Development

### Local Development
```bash
# Backend development
cd gateway
mvn spring-boot:run

# Frontend development
cd frontend
npm install
npm start
```

### Testing
```bash
# Run tests
docker-compose exec gateway mvn test
docker-compose exec frontend npm test
```

## 🤝 Contributing

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

MIT License - xem file LICENSE để biết thêm chi tiết.

## 📞 Support

- Email: support@kindledger.com
- Documentation: https://docs.kindledger.com
- Issues: https://github.com/kindledger/issues
