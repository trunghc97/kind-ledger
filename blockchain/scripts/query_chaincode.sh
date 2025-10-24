#!/bin/bash

# Kind-Ledger Chaincode Query Script
# Test invoke và query chaincode

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Chaincode parameters
CHANNEL_NAME="kindchannel"
CHAINCODE_NAME="kindledgercc"

echo -e "${GREEN}🔍 Kind-Ledger Chaincode Query${NC}"
echo "=================================="

# Khởi tạo ledger
init_ledger() {
    echo -e "${YELLOW}🚀 Khởi tạo ledger...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer chaincode invoke \
        -o orderer.kindledger.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        --peerAddresses peer0.mb.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.charity.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.supplier.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.auditor.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -c '{"function":"InitLedger","Args":[]}'
    
    echo -e "${GREEN}✅ Ledger đã được khởi tạo${NC}"
}

# Tạo campaign mới
create_campaign() {
    echo -e "${YELLOW}📝 Tạo campaign mới...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer chaincode invoke \
        -o orderer.kindledger.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        --peerAddresses peer0.mb.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.charity.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.supplier.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.auditor.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -c '{"function":"CreateCampaign","Args":["campaign-003","Hỗ trợ người già","Hỗ trợ người già có hoàn cảnh khó khăn","charity-org","20000000"]}'
    
    echo -e "${GREEN}✅ Campaign mới đã được tạo${NC}"
}

# Quyên góp
donate() {
    echo -e "${YELLOW}💰 Thực hiện quyên góp...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer chaincode invoke \
        -o orderer.kindledger.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp/tlscacerts/tlsca.kindledger.com-cert.pem \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        --peerAddresses peer0.mb.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.charity.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.supplier.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt \
        --peerAddresses peer0.auditor.kindledger.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -c '{"function":"Donate","Args":["campaign-001","donor-001","Nguyễn Văn A","5000000"]}'
    
    echo -e "${GREEN}✅ Quyên góp đã được thực hiện${NC}"
}

# Query campaign
query_campaign() {
    echo -e "${YELLOW}🔍 Query campaign...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer chaincode query \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        -c '{"function":"QueryCampaign","Args":["campaign-001"]}'
}

# Query tất cả campaigns
query_all_campaigns() {
    echo -e "${YELLOW}📋 Query tất cả campaigns...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=MBBankMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051 \
        cli peer chaincode query \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        -c '{"function":"QueryAllCampaigns","Args":[]}'
}

# Query từ Auditor peer (read-only)
query_from_auditor() {
    echo -e "${YELLOW}🔍 Query từ Auditor peer (read-only)...${NC}"
    
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp \
        -e CORE_PEER_ADDRESS=peer0.auditor.kindledger.com:7051 \
        cli peer chaincode query \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        -c '{"function":"QueryCampaign","Args":["campaign-001"]}'
}

# Hiển thị help
show_help() {
    echo -e "${GREEN}Kind-Ledger Chaincode Query Script${NC}"
    echo "=================================="
    echo ""
    echo "Sử dụng: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init         - Khởi tạo ledger"
    echo "  create       - Tạo campaign mới"
    echo "  donate       - Thực hiện quyên góp"
    echo "  query        - Query campaign"
    echo "  queryall     - Query tất cả campaigns"
    echo "  auditor      - Query từ Auditor peer"
    echo "  test         - Chạy tất cả test cases"
    echo "  help         - Hiển thị help này"
    echo ""
    echo "Ví dụ:"
    echo "  $0 init                    # Khởi tạo ledger"
    echo "  $0 query                   # Query campaign"
    echo "  $0 test                    # Chạy tất cả test"
}

# Chạy tất cả test cases
run_all_tests() {
    echo -e "${YELLOW}🧪 Chạy tất cả test cases...${NC}"
    
    init_ledger
    sleep 2
    
    create_campaign
    sleep 2
    
    donate
    sleep 2
    
    echo -e "${YELLOW}📊 Kết quả query campaign-001:${NC}"
    query_campaign
    
    echo -e "\n${YELLOW}📋 Kết quả query tất cả campaigns:${NC}"
    query_all_campaigns
    
    echo -e "\n${YELLOW}🔍 Kết quả query từ Auditor:${NC}"
    query_from_auditor
    
    echo -e "${GREEN}🎉 Tất cả test cases đã hoàn thành!${NC}"
}

# Main function
main() {
    case "${1:-help}" in
        init)
            init_ledger
            ;;
        create)
            create_campaign
            ;;
        donate)
            donate
            ;;
        query)
            query_campaign
            ;;
        queryall)
            query_all_campaigns
            ;;
        auditor)
            query_from_auditor
            ;;
        test)
            run_all_tests
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Command không hợp lệ: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Chạy script
main "$@"
