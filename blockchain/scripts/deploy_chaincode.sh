#!/bin/bash

# Kind-Ledger Chaincode Deployment Script
# Package, install, approve và commit chaincode

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Thư mục gốc (repo root dựa trên vị trí script)
ROOT_DIR=$(cd "$(dirname "$0")"/../.. && pwd)
BLOCKCHAIN_DIR="$ROOT_DIR/blockchain"
CHAINCODE_DIR="$BLOCKCHAIN_DIR/chaincode/kindledgercc"

# Chaincode parameters
CHANNEL_NAME="kindchannel"
CHAINCODE_NAME="kindledgercc"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="1"
CHAINCODE_PACKAGE="kindledgercc.tar.gz"

echo -e "${GREEN}📦 Kind-Ledger Chaincode Deployment${NC}"
echo "=================================="

# Đợi services sẵn sàng (tránh TLS handshake lỗi do khởi động chậm)
wait_ready() {
    echo -e "${YELLOW}⏳ Đợi services sẵn sàng (20s)...${NC}"
    sleep 20
}

# Kiểm tra chaincode directory
check_chaincode() {
    echo -e "${YELLOW}📋 Kiểm tra chaincode...${NC}"
    
    if [ ! -d "$CHAINCODE_DIR" ]; then
        echo -e "${RED}❌ Chaincode directory không tồn tại: $CHAINCODE_DIR${NC}"
        exit 1
    fi
    
    if [ ! -f "$CHAINCODE_DIR/main.go" ]; then
        echo -e "${RED}❌ main.go không tồn tại trong chaincode directory${NC}"
        exit 1
    fi
    
    if [ ! -f "$CHAINCODE_DIR/chaincode.go" ]; then
        echo -e "${RED}❌ chaincode.go không tồn tại trong chaincode directory${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Chaincode đã sẵn sàng${NC}"
}

# Package chaincode
package_chaincode() {
    echo -e "${YELLOW}📦 Package chaincode...${NC}"
    
    cd "$CHAINCODE_DIR"
    
    # Xóa package cũ nếu có
    if [ -f "$CHAINCODE_PACKAGE" ]; then
        rm "$CHAINCODE_PACKAGE"
    fi
    
    # Package chaincode
    docker exec -w /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/chaincode/kindledgercc \
        fabric-tools peer lifecycle chaincode package $CHAINCODE_PACKAGE \
        --path /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/chaincode/kindledgercc \
        --lang golang \
        --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION} || true

    # Copy package về host
    docker cp fabric-tools:/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/chaincode/kindledgercc/$CHAINCODE_PACKAGE "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Chaincode đã được package${NC}"
}

# Install chaincode trên tất cả peers
install_chaincode() {
    echo -e "${YELLOW}📥 Install chaincode trên tất cả peers...${NC}"
    wait_ready
    
    # Copy package vào từng peer và cài đặt ngay trong peer container (tránh TLS giữa containers)
    echo -e "${YELLOW}🏦 Install trên MBBank peer...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.mb.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.mb.kindledger.com peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE || true

    echo -e "${YELLOW}❤️  Install trên Charity peer...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.charity.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.charity.kindledger.com peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE || true

    echo -e "${YELLOW}🏪 Install trên Supplier peer...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.supplier.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.supplier.kindledger.com peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE || true

    echo -e "${YELLOW}🔍 Install trên Auditor peer...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.auditor.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.auditor.kindledger.com peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE || true

    echo -e "${GREEN}✅ Chaincode đã được install trên tất cả peers${NC}"
}

# Lấy package ID
get_package_id() {
    echo -e "${YELLOW}🔍 Lấy package ID...${NC}"
    
    PACKAGE_ID=$(docker exec peer0.mb.kindledger.com peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id')
    
    echo -e "${GREEN}✅ Package ID: $PACKAGE_ID${NC}"
}

# Approve chaincode cho tất cả organizations
approve_chaincode() {
    echo -e "${YELLOW}✅ Approve chaincode cho tất cả organizations...${NC}"
    wait_ready
    
    # Approve cho MBBank
    echo -e "${YELLOW}🏦 Approve cho MBBank...${NC}"
    docker exec fabric-tools peer lifecycle chaincode approveformyorg \
        -o orderer:7050 \
        --ordererTLSHostnameOverride orderer.orderer.kindledger.com \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/orderers/orderer.orderer.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.mb.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt || true
    
    # Approve cho Charity
    echo -e "${YELLOW}❤️  Approve cho Charity...${NC}"
    docker exec fabric-tools peer lifecycle chaincode approveformyorg \
        -o orderer:7050 \
        --ordererTLSHostnameOverride orderer.orderer.kindledger.com \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/orderers/orderer.orderer.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.charity.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt || true
    
    # Approve cho Supplier
    echo -e "${YELLOW}🏪 Approve cho Supplier...${NC}"
    docker exec fabric-tools peer lifecycle chaincode approveformyorg \
        -o orderer:7050 \
        --ordererTLSHostnameOverride orderer.orderer.kindledger.com \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/orderers/orderer.orderer.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.supplier.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt || true
    
    # Approve cho Auditor
    echo -e "${YELLOW}🔍 Approve cho Auditor...${NC}"
    docker exec fabric-tools peer lifecycle chaincode approveformyorg \
        -o orderer:7050 \
        --ordererTLSHostnameOverride orderer.orderer.kindledger.com \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/orderers/orderer.orderer.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.auditor.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt || true
    
    echo -e "${GREEN}✅ Chaincode đã được approve bởi tất cả organizations${NC}"
}

# Commit chaincode
commit_chaincode() {
    echo -e "${YELLOW}🚀 Commit chaincode...${NC}"
    wait_ready
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        fabric-tools peer lifecycle chaincode commit \
        -o orderer:7050 \
        --ordererTLSHostnameOverride orderer.orderer.kindledger.com \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/orderers/orderer.orderer.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.mb.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.charity.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.supplier.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.auditor.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt || true
    
    echo -e "${GREEN}✅ Chaincode đã được commit thành công${NC}"
}

# Kiểm tra chaincode
check_chaincode() {
    echo -e "${YELLOW}🔍 Kiểm tra chaincode...${NC}"
    docker exec \
        fabric-tools peer lifecycle chaincode querycommitted \
        --channelID $CHANNEL_NAME --name $CHAINCODE_NAME \
        --peerAddresses peer0.mb.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt || true
}

# Main function
main() {
    check_chaincode
    package_chaincode
    install_chaincode
    get_package_id
    approve_chaincode
    commit_chaincode
    
    echo -e "${GREEN}🎉 Chaincode $CHAINCODE_NAME đã được deploy thành công!${NC}"
    
    check_chaincode
}

# Chạy script
main "$@"
