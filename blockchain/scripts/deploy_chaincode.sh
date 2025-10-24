#!/bin/bash

# Kind-Ledger Chaincode Deployment Script
# Package, install, approve và commit chaincode

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Thư mục gốc
ROOT_DIR=$(pwd)
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
    docker exec cli peer lifecycle chaincode package $CHAINCODE_PACKAGE \
        --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/kindledgercc \
        --lang golang \
        --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}
    
    echo -e "${GREEN}✅ Chaincode đã được package${NC}"
}

# Install chaincode trên tất cả peers
install_chaincode() {
    echo -e "${YELLOW}📥 Install chaincode trên tất cả peers...${NC}"
    
    # Install trên MBBank peer
    echo -e "${YELLOW}🏦 Install trên MBBank peer...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer lifecycle chaincode install $CHAINCODE_PACKAGE
    
    # Install trên Charity peer
    echo -e "${YELLOW}❤️  Install trên Charity peer...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=CharityMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051 \
        cli peer lifecycle chaincode install $CHAINCODE_PACKAGE
    
    # Install trên Supplier peer
    echo -e "${YELLOW}🏪 Install trên Supplier peer...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=SupplierMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051 \
        cli peer lifecycle chaincode install $CHAINCODE_PACKAGE
    
    # Install trên Auditor peer
    echo -e "${YELLOW}🔍 Install trên Auditor peer...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 \
        cli peer lifecycle chaincode install $CHAINCODE_PACKAGE
    
    echo -e "${GREEN}✅ Chaincode đã được install trên tất cả peers${NC}"
}

# Lấy package ID
get_package_id() {
    echo -e "${YELLOW}🔍 Lấy package ID...${NC}"
    
    PACKAGE_ID=$(docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id')
    
    echo -e "${GREEN}✅ Package ID: $PACKAGE_ID${NC}"
}

# Approve chaincode cho tất cả organizations
approve_chaincode() {
    echo -e "${YELLOW}✅ Approve chaincode cho tất cả organizations...${NC}"
    
    # Approve cho MBBank
    echo -e "${YELLOW}🏦 Approve cho MBBank...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.kindledger.com:7050 \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    # Approve cho Charity
    echo -e "${YELLOW}❤️  Approve cho Charity...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=CharityMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051 \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.kindledger.com:7050 \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    # Approve cho Supplier
    echo -e "${YELLOW}🏪 Approve cho Supplier...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=SupplierMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051 \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.kindledger.com:7050 \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    # Approve cho Auditor
    echo -e "${YELLOW}🔍 Approve cho Auditor...${NC}"
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.kindledger.com:7050 \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $PACKAGE_ID \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
    
    echo -e "${GREEN}✅ Chaincode đã được approve bởi tất cả organizations${NC}"
}

# Commit chaincode
commit_chaincode() {
    echo -e "${YELLOW}🚀 Commit chaincode...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer lifecycle chaincode commit \
        -o orderer.kindledger.com:7050 \
        --channelID $CHANNEL_NAME \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --sequence $CHAINCODE_SEQUENCE \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem \
        --peerAddresses peer0.mb.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.charity.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.supplier.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.auditor.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt
    
    echo -e "${GREEN}✅ Chaincode đã được commit thành công${NC}"
}

# Kiểm tra chaincode
check_chaincode() {
    echo -e "${YELLOW}🔍 Kiểm tra chaincode...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME
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
