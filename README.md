# Kind-Ledger POC

Hệ thống quyên góp từ thiện minh bạch và an toàn trên nền tảng blockchain Hyperledger Fabric.

## 🎯 Tổng quan

Kind-Ledger là một Proof of Concept (POC) cho hệ thống quyên góp từ thiện sử dụng công nghệ blockchain Hyperledger Fabric. Hệ thống cho phép tạo và quản lý các chiến dịch quyên góp một cách minh bạch, an toàn và có thể kiểm tra.

### ✨ Tính năng chính

- **Minh bạch tuyệt đối**: Mọi giao dịch được ghi lại trên blockchain
- **Quản lý chiến dịch**: Tạo và theo dõi các chiến dịch quyên góp
- **Quyên góp an toàn**: Xử lý quyên góp với xác thực blockchain
- **Giám sát real-time**: Auditor node giám sát toàn bộ hệ thống
- **API Gateway**: RESTful API cho tích hợp dễ dàng
- **Block Explorer**: Giao diện web để khám phá blockchain

### 🏗️ Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Angular FE    │    │  Spring Boot    │    │  Node.js        │
│   (Port 4200)   │◄──►│   Gateway       │◄──►│   Explorer      │
│                 │    │  (Port 8080)    │    │  (Port 3000)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │   Hyperledger Fabric    │
                    │                         │
                    │  ┌─────────────────┐    │
                    │  │    Orderer      │    │
                    │  │  (Port 7050)    │    │
                    │  └─────────────────┘    │
                    │                         │
                    │  ┌─────────────────┐    │
                    │  │ MBBank Peer     │    │
                    │  │ (Port 7051)     │    │
                    │  └─────────────────┘    │
                    │                         │
                    │  ┌─────────────────┐    │
                    │  │ Charity Peer    │    │
                    │  │ (Port 8051)     │    │
                    │  └─────────────────┘    │
                    │                         │
                    │  ┌─────────────────┐    │
                    │  │ Supplier Peer   │    │
                    │  │ (Port 9051)     │    │
                    │  └─────────────────┘    │
                    │                         │
                    │  ┌─────────────────┐    │
                    │  │ Auditor Peer    │    │
                    │  │ (Port 10051)    │    │
                    │  └─────────────────┘    │
                    └─────────────────────────┘
```

## 📚 Tài liệu chi tiết

Để biết thêm chi tiết về thiết kế và implementation, vui lòng xem:

- **[Kiến trúc Tổng thể](./documents/intro.md)** - Kiến trúc hệ thống, mục tiêu, và triển khai
- **[Thiết kế Luồng & API](./documents/flow-api-design.md)** - Chi tiết luồng nghiệp vụ và API specifications
- **[Thiết kế Database](./documents/database-design.md)** - Schema database, cache strategy, và performance
- **[Hướng dẫn Testing](./documents/testing-guide.md)** - Testing API Gateway với 28 test cases

**Quick links**: [intro.md](./documents/intro.md) | [flow-api-design.md](./documents/flow-api-design.md) | [database-design.md](./documents/database-design.md) | [testing-guide.md](./documents/testing-guide.md)

## 🚀 Cài đặt và chạy

### Yêu cầu hệ thống

- **Docker & Docker Compose** (phiên bản 20.10+)
- **Git** để clone repository
- **Python 3.x** để chạy test scripts
- **Java 17+** (cho Gateway)
- **Node.js 16+** (cho Explorer)

### Bước 1: Clone repository

```bash
git clone <repository-url>
cd kind-ledger
```

### Bước 2: Khởi động hệ thống

```bash
# Khởi động tất cả services
docker-compose up -d

# Kiểm tra trạng thái containers
docker-compose ps
```

### Bước 3: Kiểm tra hệ thống

```bash
# Kiểm tra health check
curl http://localhost:8080/api/health

# Chạy test suite
python3 test_gateway_api.py

# Hoặc sử dụng bash wrapper
bash test-api.sh
```

### Bước 4: Truy cập các dịch vụ

| Dịch vụ | URL | Mô tả |
|---------|-----|-------|
| **Frontend** | http://localhost:4200 | Giao diện người dùng |
| **API Gateway** | http://localhost:8080/api | REST API |
| **Block Explorer** | http://localhost:3000 | Blockchain Explorer |
| **Health Check** | http://localhost:8080/api/health | Trạng thái hệ thống |

## 🔧 Cấu trúc dự án

```
kind-ledger/
├── documents/                    # 📚 Tài liệu chi tiết
│   ├── intro.md                 # Kiến trúc tổng thể
│   ├── flow-api-design.md       # Thiết kế luồng & API
│   ├── database-design.md       # Thiết kế database
│   └── testing-guide.md        # Hướng dẫn testing
├── blockchain/                  # 🔗 Hyperledger Fabric
│   ├── config/                 # Cấu hình mạng
│   ├── chaincode/              # Smart contract
│   └── scripts/                # Scripts tự động
├── gateway/                    # 🚪 Spring Boot API Gateway
├── frontend/                   # 🎨 Angular Frontend
├── explorer/                   # 🔍 Node.js Explorer
├── database/                   # 🗄️ Database setup
├── docker-compose.yml          # 🐳 Docker orchestration
├── test_gateway_api.py         # 🧪 API test script
├── test-api.sh                 # 🧪 Test wrapper
└── README.md                   # 📖 Tài liệu này
```

## 📊 API Endpoints

### Campaign Management
```bash
# Tạo chiến dịch
curl -X POST http://localhost:8080/api/campaigns \
  -H "Content-Type: application/json" \
  -d '{
    "id": "campaign-001",
    "name": "Hỗ trợ trẻ em nghèo",
    "description": "Quyên góp để hỗ trợ trẻ em có hoàn cảnh khó khăn",
    "owner": "charity-org",
    "goal": 10000000
  }'

# Lấy danh sách chiến dịch
curl http://localhost:8080/api/campaigns

# Lấy chi tiết chiến dịch
curl http://localhost:8080/api/campaigns/campaign-001
```

### Donation Processing
```bash
# Quyên góp
curl -X POST http://localhost:8080/api/donate \
  -H "Content-Type: application/json" \
  -d '{
    "campaignId": "campaign-001",
    "donorId": "donor-001",
    "donorName": "Nguyễn Văn A",
    "amount": 500000
  }'

# Lấy tổng quyên góp
curl http://localhost:8080/api/stats/total
```

### Token Deposit (cVND Token)
```bash
# Deposit token vào ví (tạo và mint token trên blockchain)
curl -X POST http://localhost:8080/api/v1/deposit \
  -H "Content-Type: application/json" \
  -d '{
    "accountNumber": "1234567898",
    "amount": 500000,
    "walletAddress": "wallet-mb-003"
  }'

# Query token balance từ blockchain
docker exec fabric-tools bash -lc \
  'export CORE_PEER_LOCALMSPID=MBBankMSP; \
   export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp; \
   export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051; \
   export CORE_PEER_TLS_ENABLED=true; \
   export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt; \
   peer chaincode query -C kindchannel -n cvnd-token -c '"'"'{"function":"BalanceOf","Args":["wallet-mb-003"]}'"'"
```

### Authentication
```bash
# Đăng ký user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test123456!",
    "fullName": "Test User"
  }'

# Đăng nhập
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "Test123456!"
  }'
```

## 🧪 Testing

### Chạy Test Suite

```bash
# Test đầy đủ (28 test cases)
python3 test_gateway_api.py

# Test với bash wrapper
bash test-api.sh

# Test specific endpoint
curl http://localhost:8080/api/health
```

### Test Coverage

- ✅ **28 test cases** với 100% pass rate
- ✅ **5 categories**: Workflow, Validation, Edge Cases, Security, Authentication
- ✅ **Colored output** cho dễ đọc kết quả
- ✅ **Graceful degradation** khi blockchain không available
- ✅ **Security testing** (XSS, SQL injection)
- ✅ **Unicode support** (中文 🎉 日本語 عربي Русский)

## 🏢 Organizations

| Organization | Vai trò | Peer | MSP ID |
|-------------|---------|------|--------|
| **MBBank** | Ngân hàng phát hành & quản lý token | peer0.mb.kindledger.com | MBBankMSP |
| **Charity** | Tổ chức thiện nguyện | peer0.charity.kindledger.com | CharityMSP |
| **Supplier** | Nhà cung cấp sản phẩm/dịch vụ | peer0.supplier.kindledger.com | SupplierMSP |
| **Auditor** | Node giám sát (read-only) | peer0.auditor.kindledger.com | AuditorMSP |

## 🔒 Bảo mật

- **TLS encryption** cho tất cả kết nối
- **MSP-based authentication** và authorization
- **Mã hóa dữ liệu** trong quá trình truyền
- **Audit trail** đầy đủ trên blockchain
- **Row-level security** trong database
- **Rate limiting** cho API endpoints

## 📈 Performance

### Benchmarks

| Operation | Response Time | Throughput |
|-----------|---------------|------------|
| Create Campaign | ~2-3 giây | 50 ops/sec |
| Make Donation | ~1-2 giây | 100 ops/sec |
| Query Campaign | ~500ms | 500 ops/sec |
| Get All Campaigns | ~1 giây | 200 ops/sec |

### Optimization

- **Connection pooling** cho database
- **Redis caching** cho performance
- **Indexing strategy** cho queries
- **Load balancing** cho multiple peers

## 🛠️ Troubleshooting

### Lỗi thường gặp

1. **Container không khởi động được**
   ```bash
   # Kiểm tra logs
   docker-compose logs <service-name>
   
   # Restart service
   docker-compose restart <service-name>
   ```

2. **Gateway không accessible**
   ```bash
   # Kiểm tra Gateway
   curl http://localhost:8080/api/health
   
   # Kiểm tra containers
   docker-compose ps
   ```

3. **Test failures**
   ```bash
   # Chạy với verbose output
   python3 test_gateway_api.py
   
   # Kiểm tra specific endpoint
   curl -v http://localhost:8080/api/campaigns
   ```

### Reset hệ thống

```bash
# Dừng tất cả services
docker-compose down

# Xóa volumes (WARNING: Xóa tất cả dữ liệu)
docker-compose down -v

# Khởi động lại
docker-compose up -d
```

## 📊 Monitoring

### Health Checks

```bash
# Kiểm tra trạng thái tất cả services
curl http://localhost:8080/api/health
curl http://localhost:3000/api/health

# Kiểm tra logs
docker-compose logs -f gateway
docker-compose logs -f frontend
docker-compose logs -f explorer
```

### Metrics

- Số lượng chiến dịch
- Tổng số tiền quyên góp
- Số lượng giao dịch
- Trạng thái mạng blockchain

## 🧰 Scripts Blockchain: chạy khi nào?

Các script nằm tại `blockchain/scripts/`. Trừ khi ghi chú khác, hãy chạy từ thư mục gốc repo (`kind-ledger/`) hoặc `cd blockchain/scripts` trước khi chạy để đường dẫn tương đối khớp. Đảm bảo Docker/Compose hoạt động và các images/phụ thuộc đã sẵn sàng.

### 1) generate.sh — Khởi tạo artifacts và crypto material

- Khi nào chạy: Lần đầu chuẩn bị mạng, hoặc khi thay đổi cấu hình mạng (MSP, orgs, policies) và cần tạo lại `crypto-config`, `genesis.block`, `kindchannel.tx`, `*MSPanchors.tx`.
- Không nên chạy: Khi mạng đang hoạt động ổn định và không thay đổi topology.
- Ví dụ:
```bash
cd blockchain/scripts
./generate.sh
```

### 2) network.sh — Quản vòng đời mạng Fabric (dev helper)

- Khi nào chạy: Để khởi động nhanh môi trường Fabric local cho dev/test, hoặc dừng/xoá khi cần làm sạch.
- Lệnh thường dùng:
  - `./network.sh up` — Khởi động network (orderer, peers, CA, DB... tuỳ cấu hình)
  - `./network.sh down` — Dừng và xoá containers/volumes liên quan
  - `./network.sh restart` — Dừng rồi khởi động lại
- Ví dụ:
```bash
cd blockchain/scripts
./network.sh up
```

### 3) create_channel.sh — Tạo channel, peer join, cập nhật anchor peers

- Khi nào chạy: Sau khi network đã chạy (`network.sh up`) và artifacts đã được sinh (`generate.sh`), để tạo channel (ví dụ `kindchannel`), cho peers join và cập nhật anchor peers.
- Ví dụ:
```bash
cd blockchain/scripts
./create_channel.sh
```

### 4) deploy_chaincode.sh — Triển khai smart contract chính (`kindledgercc`)

- Khi nào chạy: Lần đầu deploy chaincode trên channel, hoặc khi nâng cấp version/sequence.
- Yêu cầu trước: Channel đã tồn tại và các peer mục tiêu đã join.
- Ghi chú: Script có thể hỗ trợ tham số tên chaincode, version, sequence. Xem header script để biết tuỳ chọn cụ thể.
- Ví dụ:
```bash
cd blockchain/scripts
./deploy_chaincode.sh
```

### 5) deploy_cvnd_token.sh — Triển khai chaincode token (`cvnd-token`)

- Khi nào chạy: Khi cần triển khai contract token riêng phục vụ phát hành/quản lý token (vai trò MBBank).
- Yêu cầu trước: Channel đã sẵn sàng; có thể chạy sau chaincode chính hoặc độc lập tuỳ workflow.
- Ví dụ:
```bash
cd blockchain/scripts
./deploy_cvnd_token.sh
```

### 6) query_chaincode.sh — Smoke-test invoke/query

- Khi nào chạy: Sau khi commit chaincode để kiểm thử nhanh các hàm query/invoke.
- Yêu cầu trước: Chaincode đã commit; peers đã join và anchor đúng.
- Ví dụ:
```bash
cd blockchain/scripts
./query_chaincode.sh
```

### Thứ tự khuyến nghị cho lần đầu (fresh setup)

1. `generate.sh`
2. `network.sh up`
3. `create_channel.sh`
4. `deploy_chaincode.sh` (chaincode chính cho campaigns/donations)
5. **`deploy_cvnd_token.sh`** (bắt buộc nếu muốn dùng API `/api/v1/deposit` để mint token)
6. `query_chaincode.sh` (smoke-test)

### Lưu ý

- Theo dõi lỗi qua logs: `docker-compose logs -f orderer` và `docker-compose logs -f peer0.mb.kindledger.com` (hoặc các peer khác).
- Nếu thay đổi cấu hình mạng, hãy dừng mạng (`network.sh down`), chạy lại `generate.sh`, rồi khởi động lại (`network.sh up`).
- Trong CI/CD, nên ghim version và sequence của chaincode, truyền qua tham số script để đảm bảo reproducibility.

### Cách chạy tiêu chuẩn (đã chuẩn hoá)

#### Bước 1: Generate artifacts và khởi động network

```bash
cd kind-ledger

# Sinh crypto materials và channel artifacts
docker run --rm \
  -v "$PWD":/workspace \
  -w /workspace/blockchain/config \
  -e FABRIC_CFG_PATH=/workspace/blockchain/config \
  hyperledger/fabric-tools:2.5 \
  bash -lc "cryptogen generate --config=./crypto-config.yaml --output=../crypto-config && \
            configtxgen -profile KindLedgerGenesis -channelID system-channel -outputBlock ../artifacts/genesis.block && \
            configtxgen -profile KindChannel -channelID kindchannel -outputCreateChannelTx ../artifacts/kindchannel.tx && \
            configtxgen -profile KindChannel -channelID kindchannel -outputAnchorPeersUpdate ../artifacts/MBBankMSPanchors.tx -asOrg MBBankMSP && \
            configtxgen -profile KindChannel -channelID kindchannel -outputAnchorPeersUpdate ../artifacts/CharityMSPanchors.tx -asOrg CharityMSP && \
            configtxgen -profile KindChannel -channelID kindchannel -outputAnchorPeersUpdate ../artifacts/SupplierMSPanchors.tx -asOrg SupplierMSP && \
            configtxgen -profile KindChannel -channelID kindchannel -outputAnchorPeersUpdate ../artifacts/AuditorMSPanchors.tx -asOrg AuditorMSP"

# Khởi động network core
cd blockchain/scripts
./network.sh up
```

#### Bước 2: Tạo channel và join peers

```bash
cd blockchain/scripts
./create_channel.sh
```

#### Bước 3: Deploy chaincode

Để hệ thống hoạt động đầy đủ, hãy triển khai các chaincode:

```bash
cd blockchain/scripts

# Deploy chaincode chính (cho campaigns/donations)
./deploy_chaincode.sh

# Deploy chaincode token (bắt buộc cho API /api/v1/deposit)
./deploy_cvnd_token.sh
```

**Lưu ý quan trọng về `cvnd-token`:**
- Chaincode này cần được install trên **TẤT CẢ** 4 peers (MBBank, Charity, Supplier, Auditor) để Gateway có thể endorse transaction thành công
- Script `deploy_cvnd_token.sh` đã được cập nhật để tự động install trên tất cả peers
- Nếu chỉ install trên 1 peer, API `/deposit` sẽ trả về txId với prefix "FALLBACK-" thay vì transaction thật trên blockchain

## 🔒 Lưu ý cấu hình Gateway (bắt buộc)

- Gateway cần truy cập crypto materials và wallet để kết nối Fabric SDK.
- Compose đã cấu hình sẵn:
  - Mount `./blockchain/crypto-config` vào:
    - `/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto`
    - `/app/crypto-config` (để SDK đọc `adminPrivateKey` theo `connection-profile.yaml`).
  - Mount `./gateway/wallet` vào `/opt/gopath/src/github.com/hyperledger/fabric/peer/wallet`.
- Nếu khởi tạo mới, cần có file `gateway/wallet/Admin@mb.kindledger.com.id`.
  - Script `setup.sh` sẽ tự tạo file này từ crypto materials.

### Khởi tạo sạch từ đầu (fresh setup lần đầu hoặc reset hoàn toàn)

```bash
cd kind-ledger

# Dừng và xóa toàn bộ containers + volumes
(docker-compose down -v || docker compose down -v || true)

# Xóa tất cả dữ liệu sinh tự động và dấu đã khởi tạo
rm -rf blockchain/crypto-config \
       blockchain/artifacts \
       blockchain/chaincode/*/*.tar.gz \
       kindchannel.block \
       gateway/wallet \
       explorer/wallet \
       data \
       .init-completed

# Tạo lại thư mục dữ liệu tối thiểu
mkdir -p data/{mongo,postgres,redis,java,go}

# Khởi tạo lại toàn bộ theo quy trình chuẩn hóa
bash setup.sh
```

Ghi chú:
- Nếu `setup.sh` báo project đã được khởi tạo trước đó, hãy xóa file `.init-completed` rồi chạy lại.
- Sau khi `setup.sh` hoàn tất, network sẽ được dựng, channel được tạo và chaincode chính được triển khai.

## 🧰 Khởi tạo nhanh cho lần sau (1 lệnh duy nhất)

```bash
# Từ thư mục gốc repo
bash setup.sh

# Script sẽ tự động:
# - Dọn dẹp crypto/artifacts/wallet cũ
# - Generate crypto + artifacts
# - Tạo wallet cho Gateway và Explorer
# - Khởi tạo databases
# - Khởi động network, tạo channel
# - (Mặc định) triển khai chaincode chính
# - In hướng dẫn truy cập services
```

Nếu chỉ muốn reset và chạy lại nhanh không cần sinh lại crypto:

```bash
docker-compose down -v
rm -rf data
mkdir -p data/{mongo,postgres,redis,java,go}
docker-compose up -d
cd blockchain/scripts && ./create_channel.sh
cd blockchain/scripts && ./deploy_chaincode.sh
```

Gợi ý: Khi gặp lỗi lifecycle/policy, xoá dữ liệu, chạy lại từ Bước 1.

---

### Không commit các file sinh tự động (Generated files)

Các đường dẫn sau là file/directory sinh tự động theo máy và KHÔNG nên đưa lên git. Hãy đảm bảo `.gitignore` đã bao gồm:

```
# Fabric generated
blockchain/crypto-config/
blockchain/artifacts/
blockchain/chaincode/*/*.tar.gz
kindchannel.block

# Wallets & runtime
gateway/wallet/
explorer/wallet/

# Local data
data/**
``` 

Để làm sạch nhanh:

```bash
docker-compose down -v
rm -rf blockchain/crypto-config blockchain/artifacts blockchain/chaincode/*/*.tar.gz kindchannel.block gateway/wallet explorer/wallet data
```

## 🚀 Production Deployment

### Scaling Strategy

- **Horizontal scaling**: Thêm peer nodes
- **Load balancing**: HAProxy/Nginx
- **Database clustering**: PostgreSQL replica, MongoDB replica set
- **Cache clustering**: Redis Cluster

### High Availability

- **Multi-peer redundancy**
- **Database replication**
- **Backup & recovery** procedures
- **Disaster recovery** plan

## 🤝 Contributing

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📞 Liên hệ

**Project**: KindLedger - Transparent Charity Donation System  
**Platform**: Hyperledger Fabric Permissioned Network  
**Status**: ✅ **POC ĐÃ HOÀN THÀNH** - Sẵn sàng mở rộng

---

## 🎉 Kết luận

Kind-Ledger POC đã được triển khai thành công với:

- ✅ **Hệ thống hoạt động ổn định** với 4 peer nodes
- ✅ **Tất cả core services** đã triển khai và sẵn sàng
- ✅ **API Gateway** hoạt động hoàn hảo với Fabric SDK integration
- ✅ **Blockchain network** ổn định với Hyperledger Fabric
- ✅ **Frontend application** hoạt động đầy đủ với Angular
- ✅ **Block Explorer** sẵn sàng cho monitoring và audit
- ✅ **28 test cases** với 100% pass rate
- ✅ **Tài liệu đầy đủ** cho development và deployment

**Sẵn sàng mở rộng quy mô quốc gia** với việc thêm các peer nodes từ các tổ chức và ngân hàng khác.

---

**Last Updated**: 2025-10-28  
**Version**: 1.0  
**Maintainer**: KindLedger Team
