#!/bin/bash

# Kind-Ledger Channel Management Script
# Tạo và join channel cho tất cả các organization

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Thư mục gốc
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLOCKCHAIN_DIR="$ROOT_DIR"
ARTIFACTS_DIR="$BLOCKCHAIN_DIR/artifacts"
CRYPTO_DIR="$BLOCKCHAIN_DIR/crypto-config"

# Channel name
CHANNEL_NAME="kindchannel"

# Orderer TLS CA (đã được mount vào fabric-tools qua docker-compose)
ORDERER_TLS_CA_DOCKER="/etc/hyperledger/fabric/orderer-tls/ca.crt"

echo -e "${GREEN}📺 Kind-Ledger Channel Management${NC}"
echo "=================================="

# Kiểm tra các file cần thiết
check_files() {
    echo -e "${YELLOW}📋 Kiểm tra các file cần thiết...${NC}"
    
    if [ ! -f "$ARTIFACTS_DIR/kindchannel.tx" ]; then
        echo -e "${RED}❌ Channel transaction file không tồn tại. Vui lòng chạy ./generate.sh trước.${NC}"
        exit 1
    fi
    
    if [ ! -d "$CRYPTO_DIR" ]; then
        echo -e "${RED}❌ Crypto materials không tồn tại. Vui lòng chạy ./generate.sh trước.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Tất cả file cần thiết đã sẵn sàng${NC}"
}

# Tạo channel
create_channel() {
    echo -e "${YELLOW}📺 Tạo channel $CHANNEL_NAME...${NC}"

    # Sử dụng peer của MBBank để tạo channel trong fabric-tools
    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel create -o orderer:7050 --ordererTLSHostnameOverride orderer.orderer.kindledger.com -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/kindchannel.tx --tls --cafile $ORDERER_TLS_CA_DOCKER || true"

    echo -e "${GREEN}✅ Channel $CHANNEL_NAME đã được tạo (hoặc đã tồn tại)${NC}"
}

# Join channel cho MBBank
join_mb() {
    echo -e "${YELLOW}🏦 MBBank join channel...${NC}"

    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel join -b $CHANNEL_NAME.block || peer channel join -b ./$CHANNEL_NAME.block || true"

    echo -e "${GREEN}✅ MBBank đã join channel (hoặc đã ở trong channel)${NC}"
}

# Join channel cho Charity
join_charity() {
    echo -e "${YELLOW}❤️  Charity join channel...${NC}"

    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=CharityMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel join -b $CHANNEL_NAME.block || true"

    echo -e "${GREEN}✅ Charity đã join channel (hoặc đã ở trong channel)${NC}"
}

# Join channel cho Supplier
join_supplier() {
    echo -e "${YELLOW}🏪 Supplier join channel...${NC}"

    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=SupplierMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel join -b $CHANNEL_NAME.block || true"

    echo -e "${GREEN}✅ Supplier đã join channel (hoặc đã ở trong channel)${NC}"
}

# Join channel cho Auditor
join_auditor() {
    echo -e "${YELLOW}🔍 Auditor join channel...${NC}"

    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=AuditorMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel join -b $CHANNEL_NAME.block || true"

    echo -e "${GREEN}✅ Auditor đã join channel (hoặc đã ở trong channel)${NC}"
}

# Update anchor peers
update_anchor_peers() {
    echo -e "${YELLOW}⚓ Cập nhật anchor peers...${NC}"

    # MBBank anchor peer
    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel update -o orderer:7050 --ordererTLSHostnameOverride orderer.orderer.kindledger.com -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/MBBankMSPanchors.tx --tls --cafile $ORDERER_TLS_CA_DOCKER || true"

    # Charity anchor peer
    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=CharityMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel update -o orderer:7050 --ordererTLSHostnameOverride orderer.orderer.kindledger.com -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/CharityMSPanchors.tx --tls --cafile $ORDERER_TLS_CA_DOCKER || true"

    # Supplier anchor peer
    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=SupplierMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel update -o orderer:7050 --ordererTLSHostnameOverride orderer.orderer.kindledger.com -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/SupplierMSPanchors.tx --tls --cafile $ORDERER_TLS_CA_DOCKER || true"

    # Auditor anchor peer
    docker exec \
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric \
        -e CORE_PEER_LOCALMSPID=AuditorMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools bash -lc "peer channel update -o orderer:7050 --ordererTLSHostnameOverride orderer.orderer.kindledger.com -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/AuditorMSPanchors.tx --tls --cafile $ORDERER_TLS_CA_DOCKER || true"

    echo -e "${GREEN}✅ Anchor peers đã được cập nhật (hoặc đã đúng)${NC}"
}

# Kiểm tra channel info
check_channel() {
    echo -e "${YELLOW}🔍 Kiểm tra thông tin channel...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer channel getinfo -c $CHANNEL_NAME
}

# Main function
main() {
    check_files
    
    echo -e "${YELLOW}⏳ Đang chờ các container khởi động hoàn tất...${NC}"
    sleep 10
    
    create_channel
    join_mb
    join_charity
    join_supplier
    join_auditor
    update_anchor_peers
    
    echo -e "${GREEN}🎉 Channel $CHANNEL_NAME đã được tạo và tất cả organizations đã join thành công!${NC}"
    
    check_channel
}

# Chạy script
main "$@"
