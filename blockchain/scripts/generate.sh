#!/bin/bash

# Kind-Ledger Blockchain Scripts
# Tạo crypto materials và genesis block

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Thư mục gốc
ROOT_DIR=$(pwd)
BLOCKCHAIN_DIR="$ROOT_DIR/blockchain"
CONFIG_DIR="$BLOCKCHAIN_DIR/config"
SCRIPTS_DIR="$BLOCKCHAIN_DIR/scripts"
CRYPTO_DIR="$BLOCKCHAIN_DIR/crypto-config"
ARTIFACTS_DIR="$BLOCKCHAIN_DIR/artifacts"

echo -e "${GREEN}🚀 Kind-Ledger Blockchain Setup${NC}"
echo "=================================="

# Tạo thư mục cần thiết
create_directories() {
    echo -e "${YELLOW}📁 Tạo thư mục cần thiết...${NC}"
    
    mkdir -p "$CRYPTO_DIR"
    mkdir -p "$ARTIFACTS_DIR"
    mkdir -p "$SCRIPTS_DIR"
    
    echo -e "${GREEN}✅ Thư mục đã được tạo${NC}"
}

# Tạo crypto materials
generate_crypto() {
    echo -e "${YELLOW}🔐 Tạo crypto materials bằng Docker...${NC}"
    cd "$CONFIG_DIR"
    if [ -d "$CRYPTO_DIR" ]; then
        echo -e "${YELLOW}⚠️  Xóa crypto-config cũ...${NC}"
        rm -rf "$CRYPTO_DIR"
    fi
    docker run --rm -v "$ROOT_DIR:/opt/gopath/src/github.com/hyperledger/fabric/peer" \
      hyperledger/fabric-tools:2.5 \
      cryptogen generate --config=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/config/crypto-config.yaml \
        --output=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config
    echo -e "${GREEN}✅ Crypto materials đã được tạo${NC}"
}

# Tạo genesis block và channel transaction
generate_genesis() {
    echo -e "${YELLOW}📦 Tạo genesis block và channel transaction bằng Docker...${NC}"
    cd "$CONFIG_DIR"
    # genesis block
    docker run --rm -v "$ROOT_DIR:/opt/gopath/src/github.com/hyperledger/fabric/peer" \
      hyperledger/fabric-tools:2.5 \
      bash -c "export FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/config && \
        configtxgen -profile KindLedgerGenesis -channelID system-channel -outputBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/genesis.block"
    # channel tx
    docker run --rm -v "$ROOT_DIR:/opt/gopath/src/github.com/hyperledger/fabric/peer" \
      hyperledger/fabric-tools:2.5 \
      bash -c "export FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/config && \
        configtxgen -profile KindChannel -outputCreateChannelTx /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/kindchannel.tx -channelID kindchannel"
    # anchor peers
    for ORG in MBBankMSP CharityMSP SupplierMSP AuditorMSP; do
      docker run --rm -v "$ROOT_DIR:/opt/gopath/src/github.com/hyperledger/fabric/peer" \
        hyperledger/fabric-tools:2.5 \
        bash -c "export FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/config && \
          configtxgen -profile KindChannel -outputAnchorPeersUpdate /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/artifacts/${ORG}anchors.tx -channelID kindchannel -asOrg $ORG"
    done
    echo -e "${GREEN}✅ Genesis block và channel transactions đã được tạo${NC}"
}

# Tạo connection profile
create_connection_profile() {
    echo -e "${YELLOW}🔗 Tạo connection profile...${NC}"
    
    cat > "$CONFIG_DIR/connection-profile.yaml" << EOF
name: kindledger-network
version: "1.0"
client:
  organization: MBBank
  connection:
    timeout:
      peer:
        endorser: "300"
      orderer: "300"
channels:
  kindchannel:
    orderers:
      - orderer.kindledger.com
    peers:
      peer0.mb.kindledger.com:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true
      peer0.charity.kindledger.com:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true
      peer0.supplier.kindledger.com:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true
      peer0.auditor.kindledger.com:
        endorsingPeer: false
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true
organizations:
  MBBank:
    mspid: MBBankMSP
    peers:
      - peer0.mb.kindledger.com
    certificateAuthorities:
      - ca.mb.kindledger.com
    adminPrivateKey:
      path: crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp/keystore/priv_sk
    signedCert:
      path: crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp/signcerts/Admin@mb.kindledger.com-cert.pem
  Charity:
    mspid: CharityMSP
    peers:
      - peer0.charity.kindledger.com
    certificateAuthorities:
      - ca.charity.kindledger.com
    adminPrivateKey:
      path: crypto-config/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp/keystore/priv_sk
    signedCert:
      path: crypto-config/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp/signcerts/Admin@charity.kindledger.com-cert.pem
  Supplier:
    mspid: SupplierMSP
    peers:
      - peer0.supplier.kindledger.com
    certificateAuthorities:
      - ca.supplier.kindledger.com
    adminPrivateKey:
      path: crypto-config/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp/keystore/priv_sk
    signedCert:
      path: crypto-config/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp/signcerts/Admin@supplier.kindledger.com-cert.pem
  Auditor:
    mspid: AuditorMSP
    peers:
      - peer0.auditor.kindledger.com
    certificateAuthorities:
      - ca.auditor.kindledger.com
    adminPrivateKey:
      path: crypto-config/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp/keystore/priv_sk
    signedCert:
      path: crypto-config/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp/signcerts/Admin@auditor.kindledger.com-cert.pem
orderers:
  orderer.kindledger.com:
    url: grpc://localhost:7050
    grpcOptions:
      ssl-target-name-override: orderer.kindledger.com
      grpc.keepalive_time_ms: 60000
      grpc.keepalive_timeout_ms: 5000
      grpc.keepalive_permit_without_calls: true
      grpc.http2.max_pings_without_data: 0
      grpc.http2.min_time_between_pings_ms: 10000
      grpc.http2.min_ping_interval_without_data_ms: 300000
    tlsCACerts:
      path: crypto-config/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem
peers:
  peer0.mb.kindledger.com:
    url: grpc://localhost:7051
    grpcOptions:
      ssl-target-name-override: peer0.mb.kindledger.com
      grpc.keepalive_time_ms: 60000
      grpc.keepalive_timeout_ms: 5000
      grpc.keepalive_permit_without_calls: true
      grpc.http2.max_pings_without_data: 0
      grpc.http2.min_time_between_pings_ms: 10000
      grpc.http2.min_ping_interval_without_data_ms: 300000
    tlsCACerts:
      path: crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt
  peer0.charity.kindledger.com:
    url: grpc://localhost:8051
    grpcOptions:
      ssl-target-name-override: peer0.charity.kindledger.com
      grpc.keepalive_time_ms: 60000
      grpc.keepalive_timeout_ms: 5000
      grpc.keepalive_permit_without_calls: true
      grpc.http2.max_pings_without_data: 0
      grpc.http2.min_time_between_pings_ms: 10000
      grpc.http2.min_ping_interval_without_data_ms: 300000
    tlsCACerts:
      path: crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt
  peer0.supplier.kindledger.com:
    url: grpc://localhost:9051
    grpcOptions:
      ssl-target-name-override: peer0.supplier.kindledger.com
      grpc.keepalive_time_ms: 60000
      grpc.keepalive_timeout_ms: 5000
      grpc.keepalive_permit_without_calls: true
      grpc.http2.max_pings_without_data: 0
      grpc.http2.min_time_between_pings_ms: 10000
      grpc.http2.min_ping_interval_without_data_ms: 300000
    tlsCACerts:
      path: crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt
  peer0.auditor.kindledger.com:
    url: grpc://localhost:10051
    grpcOptions:
      ssl-target-name-override: peer0.auditor.kindledger.com
      grpc.keepalive_time_ms: 60000
      grpc.keepalive_timeout_ms: 5000
      grpc.keepalive_permit_without_calls: true
      grpc.http2.max_pings_without_data: 0
      grpc.http2.min_time_between_pings_ms: 10000
      grpc.http2.min_ping_interval_without_data_ms: 300000
    tlsCACerts:
      path: crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt
certificateAuthorities:
  ca.mb.kindledger.com:
    url: https://localhost:7054
    caName: ca-mb
    tlsCACerts:
      path: crypto-config/peerOrganizations/mb.kindledger.com/ca/ca.mb.kindledger.com-cert.pem
    httpOptions:
      verify: false
  ca.charity.kindledger.com:
    url: https://localhost:8054
    caName: ca-charity
    tlsCACerts:
      path: crypto-config/peerOrganizations/charity.kindledger.com/ca/ca.charity.kindledger.com-cert.pem
    httpOptions:
      verify: false
  ca.supplier.kindledger.com:
    url: https://localhost:9054
    caName: ca-supplier
    tlsCACerts:
      path: crypto-config/peerOrganizations/supplier.kindledger.com/ca/ca.supplier.kindledger.com-cert.pem
    httpOptions:
      verify: false
  ca.auditor.kindledger.com:
    url: https://localhost:10054
    caName: ca-auditor
    tlsCACerts:
      path: crypto-config/peerOrganizations/auditor.kindledger.com/ca/ca.auditor.kindledger.com-cert.pem
    httpOptions:
      verify: false
EOF

    echo -e "${GREEN}✅ Connection profile đã được tạo${NC}"
}

# Main function
main() {
    create_directories
    generate_crypto
    generate_genesis
    create_connection_profile
    
    echo -e "${GREEN}🎉 Hoàn thành! Tất cả crypto materials và artifacts đã được tạo.${NC}"
    echo -e "${YELLOW}📁 Các file đã được tạo:${NC}"
    echo "   - crypto-config/ (crypto materials)"
    echo "   - artifacts/genesis.block"
    echo "   - artifacts/kindchannel.tx"
    echo "   - artifacts/*MSPanchors.tx"
    echo "   - config/connection-profile.yaml"
}

# Chạy script
main "$@"
