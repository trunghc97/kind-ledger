# Deployment Checklist - Kind-Ledger

## ✅ Checklist để chạy trên máy mới

### 1. Yêu cầu hệ thống
- [ ] Docker & Docker Compose (20.10+)
- [ ] Git
- [ ] Python 3.x (cho test scripts)
- [ ] Java 17+ (cho Gateway)
- [ ] Node.js 16+ (cho Explorer)

### 2. Các file cấu hình đã được cập nhật (không cần sửa thêm)

#### Blockchain Configuration
- [x] `blockchain/config/configtx.yaml`
  - ✅ Orderer.Addresses: `orderer.orderer.kindledger.com:7050`
  - ✅ EtcdRaft.Consenters.Host: `orderer.orderer.kindledger.com`
  - ✅ TLS certificates paths đúng

- [x] `blockchain/config/crypto-config.yaml`
  - ✅ EnableNodeOUs: true (cho tất cả orgs)
  - ✅ Cần cho MSP có `config.yaml` để peers đạt policy Readers

- [x] `blockchain/config/connection-profile.yaml`
  - ✅ Orderer URL: `grpcs://orderer.orderer.kindledger.com:7050`
  - ✅ TLS paths: `/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/...`
  - ✅ Discovery: false (tắt discovery để dùng static config)

#### Scripts
- [x] `blockchain/scripts/deploy_cvnd_token.sh`
  - ✅ Install chaincode trên **TẤT CẢ** 4 peers (MBBank, Charity, Supplier, Auditor)
  - ✅ Điều này bắt buộc để Gateway có thể endorse transaction thành công

- [x] `setup.sh`
  - ✅ Mount crypto-config đúng cách vào Docker containers
  - ✅ Tạo wallet tự động

#### Docker Compose
- [x] `docker-compose.yml`
  - ✅ `FABRIC_CHAINCODENAME: cvnd-token` (thay vì kindledgercc)
  - ✅ Mount paths đúng cho crypto và wallet

#### Gateway Services
- [x] `gateway/src/main/java/com/kindledger/gateway/service/BlockchainService.java`
  - ✅ `discovery(false)` - tắt discovery
  - ✅ `createTransaction("Mint")` - tên hàm đúng (viết hoa)

- [x] `gateway/src/main/java/com/kindledger/gateway/service/FabricService.java`
  - ✅ `discovery(false)` - tắt discovery
  - ✅ Retry logic cho "Channel already exists"

### 3. Quy trình setup trên máy mới

```bash
# 1. Clone repository
git clone <repository-url>
cd kind-ledger

# 2. Fresh setup (tự động tất cả)
bash setup.sh

# Nếu setup.sh báo đã khởi tạo, xóa flag và chạy lại:
rm .init-completed && bash setup.sh

# 3. Deploy cvnd-token chaincode (bắt buộc cho deposit API)
cd blockchain/scripts
./deploy_cvnd_token.sh

# 4. Verify chaincode đã install trên tất cả peers
docker exec fabric-tools bash -lc \
  'export CORE_PEER_LOCALMSPID=MBBankMSP; \
   export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp; \
   export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051; \
   export CORE_PEER_TLS_ENABLED=true; \
   export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt; \
   peer lifecycle chaincode queryinstalled'

# Lặp lại với CharityMSP, SupplierMSP, AuditorMSP để xác nhận
```

### 4. Test API Deposit

```bash
# Test deposit API (phải trả về txId thật, không FALLBACK)
curl -X POST http://localhost:8080/api/v1/deposit \
  -H 'Content-Type: application/json' \
  -d '{
    "accountNumber": "1234567898",
    "amount": 500000,
    "walletAddress": "wallet-mb-003"
  }'

# Verify token đã vào blockchain
docker exec fabric-tools bash -lc \
  'export CORE_PEER_LOCALMSPID=MBBankMSP; \
   export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp; \
   export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051; \
   export CORE_PEER_TLS_ENABLED=true; \
   export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt; \
   peer chaincode query -C kindchannel -n cvnd-token -c '"'"'{"function":"BalanceOf","Args":["wallet-mb-003"]}'"'"''
```

### 5. Troubleshooting nếu deposit API trả FALLBACK

#### Kiểm tra chaincode đã install trên tất cả peers:
```bash
# Check từng peer
for ORG in MBBank Charity Supplier Auditor; do
  echo "=== Checking $ORG ==="
  MSP="${ORG}MSP"
  # ... run queryinstalled với env vars tương ứng
done
```

#### Nếu thiếu trên một số peers:
```bash
# Chạy lại deploy script
cd blockchain/scripts
./deploy_cvnd_token.sh
```

#### Kiểm tra logs Gateway:
```bash
docker-compose logs gateway | grep -i "fabric\|mint\|cvnd-token\|fallback"
```

### 6. Các thay đổi quan trọng đã thực hiện

1. **EnableNodeOUs trong crypto-config.yaml**
   - Cho phép MSP có `config.yaml` với Roles (admin, peer, client)
   - Cần thiết để peers đạt Readers policy và nhận được deliver events

2. **TLS Hostname trong configtx.yaml**
   - Orderer hostname: `orderer.orderer.kindledger.com` (khớp với cert CN)
   - Fix deliver timeout khi approve/commit chaincode

3. **Install chaincode trên tất cả peers**
   - Gateway cần tất cả peers có chaincode để endorse transaction
   - Chỉ cần 1 peer thiếu là sẽ báo "chaincode not installed"

4. **Tắt Discovery trong Gateway**
   - Dùng static peer configuration từ connection-profile.yaml
   - Tránh lỗi discovery khi peers chưa sync đầy đủ

### 7. Files KHÔNG nên commit (đã có trong .gitignore)

- `blockchain/crypto-config/`
- `blockchain/artifacts/`
- `blockchain/chaincode/*/*.tar.gz`
- `kindchannel.block`
- `gateway/wallet/`
- `explorer/wallet/`
- `data/`
- `.init-completed`

---

**Lưu ý:** Tất cả các thay đổi này đã được áp dụng trong codebase. Chỉ cần clone và chạy `setup.sh` là đủ.


## 8. Ghi chú quan trọng để chạy trên máy khác (tránh lỗi DNS/Orderer)

Trong một số môi trường Docker, container `orderer.kindledger.com` có thể không được gán IP đúng lúc các container khác (như `fabric-tools`) khởi động, dẫn đến lỗi DNS kiểu:

- "lookup orderer on 127.0.0.11:53: no such host"
- Hoặc lệnh `peer channel create/join/update` báo lỗi không kết nối được orderer

Để tránh và xử lý nhanh:

1) Khởi động mạng theo thứ tự chuẩn

```bash
cd /Users/iteazy/Documents/Projects/kind-ledger
docker compose up -d

# Xác nhận orderer đã chạy
docker ps --format '{{.Names}}\t{{.Status}}' | grep orderer

# Orderer PHẢI có IP trong network 'kindledger_fabric-net'
docker inspect -f '{{json .NetworkSettings.Networks}}' orderer.kindledger.com
# Kỳ vọng: trường IPAddress có giá trị, ví dụ "IPAddress":"172.18.0.6"
```

Nếu `IPAddress` trống hoặc DNS trong container khác không resolve được `orderer`:

2) Khởi động lại network + orderer sạch (không đụng code)

```bash
cd /Users/iteazy/Documents/Projects/kind-ledger
docker compose rm -sf orderer || true
docker network rm kindledger_fabric-net || true
docker compose up -d

# Kiểm tra lại IP của orderer
docker inspect -f '{{json .NetworkSettings.Networks}}' orderer.kindledger.com
```

3) Làm mới DNS trong `fabric-tools`

```bash
docker restart fabric-tools
docker exec fabric-tools bash -lc 'getent hosts orderer || getent hosts orderer.kindledger.com || echo nohost'
```

4) Tạo channel và join (ưu tiên dùng alias `orderer`; nếu vẫn lỗi, dùng `orderer.kindledger.com:7050` hoặc IP của orderer kèm TLS override)

```bash
# Tạo channel
docker exec -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
  -e CORE_PEER_LOCALMSPID=MBBankMSP \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
  -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
  -e CORE_PEER_TLS_ENABLED=true \
  fabric-tools bash -lc "peer channel create -o orderer:7050 --ordererTLSHostnameOverride orderer.orderer.kindledger.com -c kindchannel -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/kindchannel.tx --tls --cafile /etc/hyperledger/fabric/orderer-tls/ca.crt"

# Nếu cần dùng IP (lấy bằng docker inspect), thay -o ${ORDERER_IP}:7050

# Join các peer
docker exec -e FABRIC_CFG_PATH=/etc/hyperledger/fabric -e CORE_PEER_LOCALMSPID=MBBankMSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 -e CORE_PEER_TLS_ENABLED=true fabric-tools bash -lc "peer channel join -b kindchannel.block"
docker exec -e FABRIC_CFG_PATH=/etc/hyperledger/fabric -e CORE_PEER_LOCALMSPID=CharityMSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp -e CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051 -e CORE_PEER_TLS_ENABLED=true fabric-tools bash -lc "peer channel join -b kindchannel.block"
docker exec -e FABRIC_CFG_PATH=/etc/hyperledger/fabric -e CORE_PEER_LOCALMSPID=SupplierMSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp -e CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051 -e CORE_PEER_TLS_ENABLED=true fabric-tools bash -lc "peer channel join -b kindchannel.block"
docker exec -e FABRIC_CFG_PATH=/etc/hyperledger/fabric -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 -e CORE_PEER_TLS_ENABLED=true fabric-tools bash -lc "peer channel join -b kindchannel.block"
```

5) Cập nhật anchor peers và deploy chaincode (nếu DNS đã OK, chỉ cần chạy script):

```bash
cd /Users/iteazy/Documents/Projects/kind-ledger/blockchain/scripts
./create_channel.sh
./deploy_cvnd_token.sh
```

6) Gọi lại API deposit và xác nhận TX thật (không FALLBACK)

```bash
curl -sS -X POST http://localhost:8080/api/v1/deposit \
  -H 'Content-Type: application/json' \
  -d '{
    "accountNumber": "1234567898",
    "amount": 500000,
    "walletAddress": "wallet-mb-003"
  }'
```

Quick fix (một dòng) nếu gặp lại lỗi DNS:

```bash
cd /Users/iteazy/Documents/Projects/kind-ledger && \
docker compose rm -sf orderer && docker network rm kindledger_fabric-net || true && \
docker compose up -d && \
docker restart fabric-tools && \
cd blockchain/scripts && ./create_channel.sh && ./deploy_cvnd_token.sh
```

