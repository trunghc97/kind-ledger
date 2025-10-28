#!/bin/bash

# Kind-Ledger Complete Initialization Script
# Script tổng hợp để khởi tạo toàn bộ project lần đầu
# Bao gồm: data directories, crypto materials, wallet, database initialization

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# File đánh dấu đã khởi tạo
INIT_FLAG_FILE=".init-completed"

echo -e "${BLUE}🚀 Kind-Ledger Complete Initialization Script${NC}"
echo "=================================================="

# Kiểm tra xem đã khởi tạo chưa
if [ -f "$INIT_FLAG_FILE" ]; then
    echo -e "${GREEN}✅ Project đã được khởi tạo trước đó.${NC}"
    echo -e "${YELLOW}💡 Để khởi tạo lại, hãy xóa file $INIT_FLAG_FILE và chạy lại script.${NC}"
    exit 0
fi

echo -e "${YELLOW}📋 Bắt đầu khởi tạo lần đầu...${NC}"

# 1. Tạo cấu trúc thư mục data
echo -e "${YELLOW}📁 Tạo cấu trúc thư mục cache và database...${NC}"
mkdir -p data/{mongo,postgres,redis,java,go,node_modules}
mkdir -p data/java/repository
mkdir -p data/go/{pkg,mod}
chmod -R 755 data/

echo -e "${GREEN}✅ Cấu trúc thư mục đã được tạo${NC}"

# 2. Xóa hết các file crypto và artifacts cũ
cleanup_old_files() {
    echo -e "${YELLOW}🧹 Xóa các file crypto và artifacts cũ...${NC}"
    
    # Xóa crypto-config
    if [ -d "blockchain/crypto-config" ]; then
        echo -e "${YELLOW}⚠️  Xóa crypto-config cũ...${NC}"
        rm -rf blockchain/crypto-config
    fi
    
    # Xóa artifacts
    if [ -d "blockchain/artifacts" ]; then
        echo -e "${YELLOW}⚠️  Xóa artifacts cũ...${NC}"
        rm -rf blockchain/artifacts
    fi
    
    # Xóa wallet
    if [ -d "gateway/wallet" ]; then
        echo -e "${YELLOW}⚠️  Xóa wallet cũ...${NC}"
        rm -rf gateway/wallet
    fi
    
    # Xóa explorer wallet
    if [ -d "explorer/wallet" ]; then
        echo -e "${YELLOW}⚠️  Xóa explorer wallet cũ...${NC}"
        rm -rf explorer/wallet
    fi
    
    # Tạo lại thư mục artifacts
    mkdir -p blockchain/artifacts
    
    echo -e "${GREEN}✅ Đã xóa các file cũ${NC}"
}

# 3. Generate crypto materials sử dụng Docker
generate_crypto() {
    echo -e "${YELLOW}🔐 Tạo crypto materials bằng Docker...${NC}"
    
    # Sử dụng Docker container để generate crypto materials
    docker run --rm -v "$(pwd):/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        hyperledger/fabric-tools:2.5 \
        cryptogen generate --config=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/config/crypto-config.yaml \
        --output=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config
    
    echo -e "${GREEN}✅ Crypto materials đã được tạo${NC}"
}

# 4. Generate genesis block và channel artifacts
generate_artifacts() {
    echo -e "${YELLOW}📦 Tạo genesis block và channel artifacts...${NC}"
    
    cd blockchain/config
    
    # Tạo genesis block bằng Docker
    docker run --rm -v "$(pwd):/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        -v "$(pwd)/../crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-config" \
        -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile KindLedgerGenesis -channelID system-channel \
        -outputBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/artifacts/genesis.block
    
    # Tạo channel transaction bằng Docker
    docker run --rm -v "$(pwd):/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        -v "$(pwd)/../crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-config" \
        -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile KindChannel -outputCreateChannelTx /opt/gopath/src/github.com/hyperledger/fabric/peer/artifacts/kindchannel.tx \
        -channelID kindchannel
    
    # Tạo anchor peer transactions bằng Docker
    docker run --rm -v "$(pwd):/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        -v "$(pwd)/../crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-config" \
        -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile KindChannel -outputAnchorPeersUpdate /opt/gopath/src/github.com/hyperledger/fabric/peer/artifacts/MBBankMSPanchors.tx \
        -channelID kindchannel -asOrg MBBankMSP
    
    docker run --rm -v "$(pwd):/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        -v "$(pwd)/../crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-config" \
        -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile KindChannel -outputAnchorPeersUpdate /opt/gopath/src/github.com/hyperledger/fabric/peer/artifacts/CharityMSPanchors.tx \
        -channelID kindchannel -asOrg CharityMSP
    
    docker run --rm -v "$(pwd):/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        -v "$(pwd)/../crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-config" \
        -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile KindChannel -outputAnchorPeersUpdate /opt/gopath/src/github.com/hyperledger/fabric/peer/artifacts/SupplierMSPanchors.tx \
        -channelID kindchannel -asOrg SupplierMSP
    
    docker run --rm -v "$(pwd):/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        -v "$(pwd)/../crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-config" \
        -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile KindChannel -outputAnchorPeersUpdate /opt/gopath/src/github.com/hyperledger/fabric/peer/artifacts/AuditorMSPanchors.tx \
        -channelID kindchannel -asOrg AuditorMSP
    
    echo -e "${GREEN}✅ Genesis block và channel artifacts đã được tạo${NC}"
    cd ../..
}

# 5. Di chuyển artifacts và crypto-config đến đúng vị trí
organize_files() {
    echo -e "${YELLOW}📂 Tổ chức lại các file...${NC}"
    
    # Di chuyển artifacts từ blockchain/config/artifacts đến blockchain/artifacts
    if [ -d "blockchain/config/artifacts" ]; then
        mv blockchain/config/artifacts/* blockchain/artifacts/ 2>/dev/null || true
        rmdir blockchain/config/artifacts 2>/dev/null || true
    fi
    
    # Di chuyển crypto-config từ blockchain/config/crypto-config đến blockchain/crypto-config
    if [ -d "blockchain/config/crypto-config" ]; then
        mv blockchain/config/crypto-config blockchain/crypto-config
    fi
    
    echo -e "${GREEN}✅ Đã tổ chức lại các file${NC}"
}

# 6. Tạo wallet identity cho gateway
create_wallet_identity() {
    echo -e "${YELLOW}👤 Tạo wallet identity cho gateway...${NC}"
    
    # Tạo thư mục wallet
    mkdir -p gateway/wallet
    
    # Đọc certificate và private key
    if [ -f "blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp/signcerts/Admin@mb.kindledger.com-cert.pem" ]; then
        CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp/signcerts/Admin@mb.kindledger.com-cert.pem)
        KEY=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp/keystore/priv_sk)
        
        # Tạo wallet identity theo định dạng JSON của Hyperledger Fabric Gateway
        cat > gateway/wallet/Admin@mb.kindledger.com.id << EOF
{
  "credentials": {
    "certificate": "${CERT}",
    "privateKey": "${KEY}"
  },
  "mspId": "MBBankMSP",
  "type": "X.509",
  "version": 1
}
EOF
        
        echo -e "${GREEN}✅ Wallet identity đã được tạo${NC}"
        echo -e "${BLUE}📁 Wallet files:${NC}"
        ls -la gateway/wallet/
    else
        echo -e "${RED}❌ Không tìm thấy admin certificate${NC}"
        echo -e "${YELLOW}💡 Wallet sẽ được tạo khi chạy gateway lần đầu${NC}"
    fi
}

# 7. Tạo explorer wallet
create_explorer_wallet() {
    echo -e "${YELLOW}🔍 Tạo wallet cho explorer...${NC}"
    
    # Tạo thư mục wallet cho explorer
    mkdir -p explorer/wallet
    
    # Copy wallet identity từ gateway (sử dụng chung identity)
    if [ -f "gateway/wallet/Admin@mb.kindledger.com.id" ]; then
        cp gateway/wallet/Admin@mb.kindledger.com.id explorer/wallet/Admin@mb.kindledger.com.id
        echo -e "${GREEN}✅ Explorer wallet đã được tạo${NC}"
    else
        echo -e "${YELLOW}⚠️  Không tìm thấy gateway wallet để copy${NC}"
    fi
}

# 8. Khởi tạo database lần đầu
init_database() {
    echo -e "${YELLOW}🗄️  Khởi tạo database lần đầu...${NC}"
    
    # Chạy PostgreSQL và MongoDB để khởi tạo database
    echo -e "${YELLOW}📊 Khởi động PostgreSQL và MongoDB...${NC}"
    docker-compose up -d postgres mongodb redis
    
    # Đợi database khởi động
    echo -e "${YELLOW}⏳ Đợi database khởi động...${NC}"
    sleep 30
    
    # Kiểm tra kết nối database
    echo -e "${YELLOW}🔍 Kiểm tra kết nối database...${NC}"
    
    # Test PostgreSQL connection
    if docker-compose exec -T postgres pg_isready -U kindledger -d kindledger; then
        echo -e "${GREEN}✅ PostgreSQL đã sẵn sàng${NC}"
    else
        echo -e "${RED}❌ PostgreSQL chưa sẵn sàng${NC}"
    fi
    
    # Test MongoDB connection
    if docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ MongoDB đã sẵn sàng${NC}"
    else
        echo -e "${RED}❌ MongoDB chưa sẵn sàng${NC}"
    fi
    
    # Dừng các service database
    echo -e "${YELLOW}🛑 Dừng database services...${NC}"
    docker-compose down
}

# 9. Tạo channel kindchannel và join peers (dùng peer CLI trong fabric-tools)
create_channel_and_join() {
    echo -e "${YELLOW}🧩 Tạo channel kindchannel và join peer MBBank...${NC}"

    # Đảm bảo core services đang chạy
    docker-compose up -d orderer peer0.mb.kindledger.com peer0.charity.kindledger.com peer0.supplier.kindledger.com peer0.auditor.kindledger.com fabric-tools

    # Đường dẫn cert
    ORDERER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/msp/tlscacerts/tlsca.orderer.kindledger.com-cert.pem
    MB_PEER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt

    # Hàm wrapper chạy peer trong fabric-tools
    run_peer() {
      docker exec -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        -e CORE_PEER_TLS_ROOTCERT_FILE=$MB_PEER_TLS_CA \
        fabric-tools bash -lc "$1"
    }

    # Tạo channel block nếu chưa có
    echo -e "${YELLOW}📺 Tạo channel block...${NC}"
    run_peer "peer channel create -o orderer.kindledger.com:7050 -c kindchannel -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/kindchannel.tx --tls --cafile $ORDERER_TLS_CA -o orderer.kindledger.com:7050 || true"

    # Join channel
    echo -e "${YELLOW}🔗 Peer MBBank join channel...${NC}"
    run_peer "peer channel join -b kindchannel.block || peer channel join -b ./kindchannel.block || true"

    # Cập nhật anchor (tùy chọn, không fail pipeline)
    echo -e "${YELLOW}📌 Cập nhật anchor peer (tuỳ chọn)...${NC}"
    run_peer "peer channel update -o orderer.kindledger.com:7050 --channelID kindchannel --tls --cafile $ORDERER_TLS_CA -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/MBBankMSPanchors.tx || true"

    echo -e "${GREEN}✅ Channel kindchannel sẵn sàng (đã join peer MBBank)${NC}"
}

# 10. Triển khai chaincode cvnd-token (nếu chưa commit)
deploy_chaincode_cvnd_token() {
    echo -e "${YELLOW}📦 Triển khai chaincode cvnd-token...${NC}"

    CHAINCODE_NAME=cvnd-token
    CHAINCODE_LABEL=cvnd-token_1
    CC_SRC=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/chaincode/cvnd-token
    ORDERER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/msp/tlscacerts/tlsca.orderer.kindledger.com-cert.pem
    MB_PEER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt

    run_peer() {
      docker exec -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        -e CORE_PEER_TLS_ROOTCERT_FILE=$MB_PEER_TLS_CA \
        fabric-tools bash -lc "$1"
    }

    # Kiểm tra đã commit chưa
    if run_peer "peer lifecycle chaincode querycommitted --channelID kindchannel | grep -q '$CHAINCODE_NAME'"; then
      echo -e "${GREEN}✅ Chaincode $CHAINCODE_NAME đã commit${NC}"
      return 0
    fi

    # Package nếu có source
    if run_peer "[ -d $CC_SRC ]"; then
      echo -e "${YELLOW}📦 Package chaincode...${NC}"
      run_peer "rm -f ${CHAINCODE_LABEL}.tar.gz; peer lifecycle chaincode package ${CHAINCODE_LABEL}.tar.gz --path $CC_SRC --lang golang --label ${CHAINCODE_LABEL} || true"

      echo -e "${YELLOW}⬆️  Install chaincode...${NC}"
      run_peer "peer lifecycle chaincode install ${CHAINCODE_LABEL}.tar.gz || true"

      PKG_ID=$(run_peer "peer lifecycle chaincode queryinstalled | grep ${CHAINCODE_LABEL} | sed -n 's/Package ID: \(.*\), Label:.*/\1/p'" | tr -d '\r')
      echo -e "${YELLOW}📦 Package ID: ${PKG_ID}${NC}"

      echo -e "${YELLOW}✅ Approve for MBBank...${NC}"
      run_peer "peer lifecycle chaincode approveformyorg --channelID kindchannel --name ${CHAINCODE_NAME} --version 1 --sequence 1 --package-id ${PKG_ID} --tls --cafile $ORDERER_TLS_CA --orderer orderer.kindledger.com:7050 || true"

      echo -e "${YELLOW}🧾 Commit chaincode...${NC}"
      run_peer "peer lifecycle chaincode commit --channelID kindchannel --name ${CHAINCODE_NAME} --version 1 --sequence 1 --tls --cafile $ORDERER_TLS_CA --orderer orderer.kindledger.com:7050 --peerAddresses peer0.mb.kindledger.com:7051 --tlsRootCertFiles $MB_PEER_TLS_CA || true"
    else
      echo -e "${YELLOW}⚠️  Không tìm thấy source chaincode tại $CC_SRC, bỏ qua bước package/install. Giả định chaincode đã có sẵn.${NC}"
    fi

    run_peer "peer lifecycle chaincode querycommitted --channelID kindchannel"
}

# Main execution
main() {
    cleanup_old_files
    generate_crypto
    generate_artifacts
    organize_files
    create_wallet_identity
    create_explorer_wallet
    init_database
    
    # Tạo file đánh dấu đã khởi tạo
    touch "$INIT_FLAG_FILE"
    
    echo ""
    echo -e "${GREEN}🎉 Hoàn thành khởi tạo lần đầu!${NC}"
    echo ""
    echo -e "${BLUE}📁 Cấu trúc đã được tạo:${NC}"
    echo "   data/mongo/          - MongoDB database"
    echo "   data/postgres/       - PostgreSQL database" 
    echo "   data/redis/          - Redis cache"
    echo "   data/java/           - Maven cache"
    echo "   data/go/             - Go modules cache"
    echo "   data/node_modules/   - npm cache"
    echo "   blockchain/crypto-config/ - Crypto materials"
    echo "   blockchain/artifacts/     - Genesis block & channel artifacts"
    echo "   gateway/wallet/          - Gateway wallet identity"
    echo "   explorer/wallet/         - Explorer wallet identity"
    echo ""
    echo -e "${BLUE}🚀 Bây giờ bạn có thể chạy:${NC}"
    echo "   docker-compose up --build"
    echo ""
    echo -e "${YELLOW}💡 Lưu ý:${NC}"
    echo "   - Dữ liệu và cache sẽ được lưu trữ trong các thư mục data/"
    echo "   - Script này chỉ chạy một lần duy nhất"
    echo "   - Để khởi tạo lại, xóa file $INIT_FLAG_FILE và chạy lại"
}

# Chạy main function
main "$@"
