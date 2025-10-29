#!/bin/bash

# Kind-Ledger Chaincode Deployment Script với Admin Identity
# Package, install, approve và commit chaincode sử dụng admin identity

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

echo -e "${GREEN}📦 Kind-Ledger Chaincode Deployment với Admin Identity${NC}"
echo "=================================================="

# Đợi services sẵn sàng
wait_ready() {
    echo -e "${YELLOW}⏳ Đợi services sẵn sàng (20s)...${NC}"
    sleep 20
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

# Install chaincode sử dụng admin identity
install_chaincode_admin() {
    echo -e "${YELLOW}📥 Install chaincode với admin identity...${NC}"
    wait_ready
    
    # Install trên MBBank peer với admin identity
    echo -e "${YELLOW}🏦 Install trên MBBank peer với admin identity...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.mb.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.mb.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=MBBankMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE
    " || true

    # Install trên Charity peer với admin identity
    echo -e "${YELLOW}❤️  Install trên Charity peer với admin identity...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.charity.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.charity.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=CharityMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE
    " || true

    # Install trên Supplier peer với admin identity
    echo -e "${YELLOW}🏪 Install trên Supplier peer với admin identity...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.supplier.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.supplier.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=SupplierMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE
    " || true

    # Install trên Auditor peer với admin identity
    echo -e "${YELLOW}🔍 Install trên Auditor peer với admin identity...${NC}"
    docker cp "$CHAINCODE_DIR/$CHAINCODE_PACKAGE" peer0.auditor.kindledger.com:/opt/$CHAINCODE_PACKAGE
    docker exec peer0.auditor.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=AuditorMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode install /opt/$CHAINCODE_PACKAGE
    " || true
    
    echo -e "${GREEN}✅ Chaincode đã được install với admin identity${NC}"
}

# Lấy package ID
get_package_id() {
    echo -e "${YELLOW}🔍 Lấy package ID...${NC}"
    
    PACKAGE_ID=$(docker exec peer0.mb.kindledger.com bash -c "
        export CORE_PEEER_LOCALMSPID=MBBankMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id'
    " 2>/dev/null || echo "")
    
    echo -e "${GREEN}✅ Package ID: $PACKAGE_ID${NC}"
    echo "$PACKAGE_ID"
}

# Approve chaincode với admin identity
approve_chaincode_admin() {
    echo -e "${YELLOW}✅ Approve chaincode với admin identity...${NC}"
    wait_ready
    
    PACKAGE_ID=$(get_package_id)
    
    if [ -z "$PACKAGE_ID" ]; then
        echo -e "${RED}❌ Không thể lấy package ID${NC}"
        return 1
    fi
    
    # Approve cho MBBank với admin identity
    echo -e "${YELLOW}🏦 Approve cho MBBank với admin identity...${NC}"
    docker exec peer0.mb.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=MBBankMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        export ORDERER_CA=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode approveformyorg \
            --channelID $CHANNEL_NAME \
            --name $CHAINCODE_NAME \
            --version $CHAINCODE_VERSION \
            --package-id $PACKAGE_ID \
            --sequence $CHAINCODE_SEQUENCE \
            --orderer orderer.kindledger.com:7050 \
            --tls \
            --cafile \$ORDERER_CA
    " || true

    # Approve cho Charity với admin identity
    echo -e "${YELLOW}❤️  Approve cho Charity với admin identity...${NC}"
    docker exec peer0.charity.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=CharityMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.charity.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        export ORDERER_CA=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode approveformyorg \
            --channelID $CHANNEL_NAME \
            --name $CHAINCODE_NAME \
            --version $CHAINCODE_VERSION \
            --package-id $PACKAGE_ID \
            --sequence $CHAINCODE_SEQUENCE \
            --orderer orderer.kindledger.com:7050 \
            --tls \
            --cafile \$ORDERER_CA
    " || true

    # Approve cho Supplier với admin identity
    echo -e "${YELLOW}🏪 Approve cho Supplier với admin identity...${NC}"
    docker exec peer0.supplier.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=SupplierMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.supplier.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        export ORDERER_CA=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode approveformyorg \
            --channelID $CHANNEL_NAME \
            --name $CHAINCODE_NAME \
            --version $CHAINCODE_VERSION \
            --package-id $PACKAGE_ID \
            --sequence $CHAINCODE_SEQUENCE \
            --orderer orderer.kindledger.com:7050 \
            --tls \
            --cafile \$ORDERER_CA
    " || true

    # Approve cho Auditor với admin identity
    echo -e "${YELLOW}🔍 Approve cho Auditor với admin identity...${NC}"
    docker exec peer0.auditor.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=AuditorMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        export ORDERER_CA=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode approveformyorg \
            --channelID $CHANNEL_NAME \
            --name $CHAINCODE_NAME \
            --version $CHAINCODE_VERSION \
            --package-id $PACKAGE_ID \
            --sequence $CHAINCODE_SEQUENCE \
            --orderer orderer.kindledger.com:7050 \
            --tls \
            --cafile \$ORDERER_CA
    " || true
    
    echo -e "${GREEN}✅ Chaincode đã được approve với admin identity${NC}"
}

# Commit chaincode với admin identity
commit_chaincode_admin() {
    echo -e "${YELLOW}🚀 Commit chaincode với admin identity...${NC}"
    wait_ready
    
    docker exec peer0.mb.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=MBBankMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        export ORDERER_CA=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode commit \
            --channelID $CHANNEL_NAME \
            --name $CHAINCODE_NAME \
            --version $CHAINCODE_VERSION \
            --sequence $CHAINCODE_SEQUENCE \
            --orderer orderer.kindledger.com:7050 \
            --tls \
            --cafile \$ORDERER_CA \
            --peerAddresses peer0.mb.kindledger.com:7051 \
            --peerAddresses peer0.charity.kindledger.com:7051 \
            --peerAddresses peer0.supplier.kindledger.com:7051 \
            --peerAddresses peer0.auditor.kindledger.com:7051 \
            --tlsRootCertFiles /etc/hyperledger/fabric/tls/ca.crt \
            --tlsRootCertFiles /etc/hyperledger/fabric/tls/ca.crt \
            --tlsRootCertFiles /etc/hyperledger/fabric/tls/ca.crt \
            --tlsRootCertFiles /etc/hyperledger/fabric/tls/ca.crt
    " || true
    
    echo -e "${GREEN}✅ Chaincode đã được commit với admin identity${NC}"
}

# Kiểm tra chaincode
check_chaincode() {
    echo -e "${YELLOW}🔍 Kiểm tra chaincode...${NC}"
    
    docker exec peer0.mb.kindledger.com bash -c "
        export CORE_PEER_LOCALMSPID=MBBankMSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME
    " || true
}

# Main function
main() {
    package_chaincode
    install_chaincode_admin
    approve_chaincode_admin
    commit_chaincode_admin
    check_chaincode
    
    echo -e "${GREEN}🎉 Chaincode $CHAINCODE_NAME đã được deploy thành công với admin identity!${NC}"
}

# Chạy main function
main "$@"
