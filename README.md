# KindLedger - Hệ thống chuyển tiền thiện nguyện token hóa

KindLedger là hệ thống chuyển tiền thiện nguyện sử dụng công nghệ blockchain với mô hình Bank-as-Node, đảm bảo minh bạch tuyệt đối trong hành trình tiền từ thiện.

## 🏗️ Kiến trúc hệ thống

Hệ thống được thiết kế theo kiến trúc microservices với các thành phần chính:

- **Frontend App** (React/Next.js) - Port: 4200
- **API Gateway** (Spring Cloud Gateway) - Port: 8080  
- **Blockchain Gateway** (Golang) - Port: 9090
- **Peer Nodes** (Golang - MB Bank & Charity) - Ports: 8082, 8083
- **Orderer Cluster** (Golang) - Ports: 7050, 7051, 7052
- **External Services** (IPFS, Explorer, Gov Observer - Golang) - Ports: 5001, 8088, 7070
- **Core Banking** (Golang Mock) - Port: 8089

## 🚀 Hướng dẫn chạy project

### Yêu cầu hệ thống

- Docker & Docker Compose
- 8GB RAM trở lên
- 20GB dung lượng trống

### Cách chạy

1. **Clone repository:**
```bash
git clone <repository-url>
cd kind-ledger
```

2. **Chạy toàn bộ hệ thống:**
```bash
docker-compose up -d
```

3. **Kiểm tra trạng thái services:**
```bash
docker-compose ps
```

4. **Xem logs của service cụ thể:**
```bash
docker-compose logs -f <service-name>
```

### 🌐 Truy cập các services

Sau khi chạy thành công, bạn có thể truy cập:

- **Frontend App**: http://localhost:4200
- **API Gateway**: http://localhost:8080
- **Block Explorer**: http://localhost:8088
- **Blockchain Gateway**: http://localhost:9090
- **MB Bank Peer**: http://localhost:8082
- **Charity Peer**: http://localhost:8083
- **Orderer-1**: http://localhost:7050
- **Gov Observer**: http://localhost:7070
- **Core Banking**: http://localhost:8089

### 🔧 Các lệnh quản lý

**Dừng tất cả services:**
```bash
docker-compose down
```

**Dừng và xóa volumes:**
```bash
docker-compose down -v
```

**Rebuild và chạy lại:**
```bash
docker-compose up --build -d
```

**Xem logs real-time:**
```bash
docker-compose logs -f
```

### 📊 Monitoring & Health Checks

Tất cả services đều có health check endpoints:

- API Gateway: http://localhost:8080/actuator/health
- Blockchain Gateway: http://localhost:9090/api/blockchain/health
- MB Bank Peer: http://localhost:8082/api/peer/health
- Charity Peer: http://localhost:8083/api/charity/health
- Orderer: http://localhost:7050/api/orderer/health
- Gov Observer: http://localhost:7070/api/observer/health
- Core Banking: http://localhost:8089/api/banking/health

### 🧪 Testing APIs

**Kiểm tra số dư:**
```bash
curl http://localhost:9090/api/blockchain/balance/0x1234567890abcdef
```

**Mint tokens:**
```bash
curl -X POST http://localhost:9090/api/blockchain/mint \
  -H "Content-Type: application/json" \
  -d '{"amount": "1000", "wallet": "0x1234567890abcdef"}'
```

**Tạo chiến dịch từ thiện:**
```bash
curl -X POST http://localhost:8083/api/charity/create-campaign \
  -H "Content-Type: application/json" \
  -d '{"title": "Hỗ trợ trẻ em", "description": "Chiến dịch hỗ trợ trẻ em nghèo", "target": "1000000", "duration": 30}'
```

**Quyên góp:**
```bash
curl -X POST http://localhost:9090/api/blockchain/donate \
  -H "Content-Type: application/json" \
  -d '{"campaignId": "camp_20231201120000", "amount": "100"}'
```

**Tạo campaign:**
```bash
curl -X POST http://localhost:8083/api/charity/create-campaign \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Campaign", "description": "Test campaign description", "target": "5000", "duration": 30}'
```

**Kiểm tra MongoDB:**
```bash
# Kết nối MongoDB Shared
docker exec -it kind-ledger-mongodb-shared-1 mongosh -u admin -p password

# Kết nối MongoDB MB Peer
docker exec -it kind-ledger-mongodb-mb-1 mongosh -u mb_admin -p mb_password

# Xem collections
use kindledger_shared
show collections
db.transactions.find().limit(5)
```

### 🐛 Troubleshooting

**Nếu services không start được:**
1. Kiểm tra ports có bị conflict không
2. Xem logs: `docker-compose logs <service-name>`
3. Restart service: `docker-compose restart <service-name>`

**Nếu frontend không kết nối được API:**
1. Kiểm tra API Gateway có chạy không
2. Kiểm tra CORS settings
3. Xem network tab trong browser dev tools

**Nếu blockchain services lỗi:**
1. Kiểm tra MongoDB có chạy không
2. Kiểm tra network connectivity giữa services
3. Xem logs của blockchain-gateway

### 📁 Cấu trúc project

```
kind-ledger/
├── docker-compose.yml          # Docker Compose configuration
├── frontend/                   # React/Next.js Frontend
├── api-gateway/               # Spring Cloud Gateway (Java)
├── blockchain-gateway/        # Blockchain Gateway Service (Golang)
├── peer-nodes/
│   ├── mb-peer/              # MB Bank Peer Node (Golang)
│   └── charity-peer/         # Charity Organization Peer (Golang)
├── orderer/                  # Orderer Service (Golang)
├── block-explorer/           # Block Explorer (Node.js)
├── gov-observer/             # Government Observer (Golang)
├── core-banking/             # Core Banking Mock (Golang)
└── documents/
    └── intro.md              # Technical Documentation
```

### 🔐 Bảo mật

- Tất cả services chạy trong Docker network riêng
- Chỉ expose ports cần thiết ra ngoài
- Sử dụng environment variables cho configuration
- Mock data cho development, production cần cấu hình thật

### 📈 Performance

- **Golang services**: Hiệu năng cao, ít tài nguyên, khởi động nhanh
- **Java API Gateway**: Ổn định, ecosystem phong phú
- **Node.js Frontend**: Development nhanh, hot reload
- Hệ thống được tối ưu cho development
- Production cần cấu hình resource limits
- Sử dụng volumes cho data persistence
- Load balancing cho high availability

### 🛠️ Tech Stack

- **Frontend**: React/Next.js, TypeScript
- **API Gateway**: Spring Cloud Gateway (Java 17)
- **Blockchain Services**: Golang 1.21, Gin framework
- **Database**: MongoDB 6.0 (Multiple instances with persistent volumes)
- **Storage**: IPFS
- **Containerization**: Docker & Docker Compose

### 🗄️ Database Architecture

**MongoDB Shared (Central)**
- Port: 27017
- Database: `kindledger_shared`
- Collections: `transactions`, `blocks`, `campaigns`, `users`, `audit_logs`

**MongoDB per Node**
- **MB Peer**: Port 27018, Database `mb_ledger`
- **Charity Peer**: Port 27019, Database `charity_ledger`
- **Orderer**: Port 27020, Database `orderer_ledger`
- **Gov Observer**: Port 27021, Database `gov_ledger`
- **Core Banking**: Port 27022, Database `banking_ledger`

**Persistent Volumes**
- Tất cả MongoDB sử dụng persistent volumes để đảm bảo dữ liệu không bị mất khi restart
- Volumes: `mongodb_shared_data`, `mongodb_mb_data`, `mongodb_charity_data`, `mongodb_orderer_data`, `mongodb_gov_data`, `mongodb_banking_data`

### 🤝 Contributing

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push và tạo Pull Request

### 📄 License

Dự án này được phát triển cho mục đích nghiên cứu và phát triển hệ thống blockchain cho thiện nguyện.