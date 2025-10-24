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
ROOT_DIR=$(pwd)
BLOCKCHAIN_DIR="$ROOT_DIR/blockchain"
ARTIFACTS_DIR="$BLOCKCHAIN_DIR/artifacts"
CRYPTO_DIR="$BLOCKCHAIN_DIR/crypto-config"

# Channel name
CHANNEL_NAME="kindchannel"

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
    
    # Sử dụng peer của MBBank để tạo channel
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer channel create \
        -o orderer.kindledger.com:7050 \
        -c $CHANNEL_NAME \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/kindchannel.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    echo -e "${GREEN}✅ Channel $CHANNEL_NAME đã được tạo${NC}"
}

# Join channel cho MBBank
join_mb() {
    echo -e "${YELLOW}🏦 MBBank join channel...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer channel join \
        -b $CHANNEL_NAME.block
    
    echo -e "${GREEN}✅ MBBank đã join channel${NC}"
}

# Join channel cho Charity
join_charity() {
    echo -e "${YELLOW}❤️  Charity join channel...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=CharityMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051 \
        cli peer channel join \
        -b $CHANNEL_NAME.block
    
    echo -e "${GREEN}✅ Charity đã join channel${NC}"
}

# Join channel cho Supplier
join_supplier() {
    echo -e "${YELLOW}🏪 Supplier join channel...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=SupplierMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051 \
        cli peer channel join \
        -b $CHANNEL_NAME.block
    
    echo -e "${GREEN}✅ Supplier đã join channel${NC}"
}

# Join channel cho Auditor
join_auditor() {
    echo -e "${YELLOW}🔍 Auditor join channel...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 \
        cli peer channel join \
        -b $CHANNEL_NAME.block
    
    echo -e "${GREEN}✅ Auditor đã join channel${NC}"
}

# Update anchor peers
update_anchor_peers() {
    echo -e "${YELLOW}⚓ Cập nhật anchor peers...${NC}"
    
    # MBBank anchor peer
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer channel update \
        -o orderer.kindledger.com:7050 \
        -c $CHANNEL_NAME \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/MBBankMSPanchors.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    # Charity anchor peer
    docker exec -e CORE_PEER_LOCALMSPID=CharityMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051 \
        cli peer channel update \
        -o orderer.kindledger.com:7050 \
        -c $CHANNEL_NAME \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/CharityMSPanchors.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    # Supplier anchor peer
    docker exec -e CORE_PEER_LOCALMSPID=SupplierMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051 \
        cli peer channel update \
        -o orderer.kindledger.com:7050 \
        -c $CHANNEL_NAME \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/SupplierMSPanchors.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    # Auditor anchor peer
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 \
        cli peer channel update \
        -o orderer.kindledger.com:7050 \
        -c $CHANNEL_NAME \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/AuditorMSPanchors.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    echo -e "${GREEN}✅ Anchor peers đã được cập nhật${NC}"
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
