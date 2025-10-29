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

