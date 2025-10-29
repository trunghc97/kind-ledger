#!/bin/bash
set -euo pipefail

echo "[cvnd-token] Deploy starting..."

ORDERER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/msp/tlscacerts/tlsca.orderer.kindledger.com-cert.pem
MB_PEER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt
CH_PEER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls/ca.crt
SP_PEER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls/ca.crt
AU_PEER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls/ca.crt

docker exec \
  -e ORDERER_TLS_CA="$ORDERER_TLS_CA" \
  -e MB_PEER_TLS_CA="$MB_PEER_TLS_CA" \
  -e CH_PEER_TLS_CA="$CH_PEER_TLS_CA" \
  -e SP_PEER_TLS_CA="$SP_PEER_TLS_CA" \
  -e AU_PEER_TLS_CA="$AU_PEER_TLS_CA" \
  fabric-tools bash -lc '
set -e;
export FABRIC_CFG_PATH=/etc/hyperledger/fabric;
export CORE_PEER_TLS_ENABLED=true;

setPeerEnv() {
  local MSPID=$1; shift
  local MSP_PATH=$1; shift
  local PEER_ADDR=$1; shift
  local TLS_CA=$1; shift
  export CORE_PEER_LOCALMSPID="$MSPID";
  export CORE_PEER_MSPCONFIGPATH="$MSP_PATH";
  export CORE_PEER_ADDRESS="$PEER_ADDR";
  export CORE_PEER_TLS_ROOTCERT_FILE="$TLS_CA";
}

cd /opt/gopath/src/github.com/hyperledger/fabric/peer;
echo "== go mod tidy & vendor";
cd blockchain/chaincode/cvnd-token && go mod tidy && go mod vendor && cd - >/dev/null;
echo "== package";
rm -f cvnd-token_1.tar.gz;
peer lifecycle chaincode package cvnd-token_1.tar.gz --path blockchain/chaincode/cvnd-token --lang golang --label cvnd-token_1;

echo "== install on all peers";
# Install on MBBank
setPeerEnv MBBankMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp peer0.mb.kindledger.com:7051 "$MB_PEER_TLS_CA";
peer lifecycle chaincode install cvnd-token_1.tar.gz || true;

# Install on Charity
setPeerEnv CharityMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp peer0.charity.kindledger.com:7051 "$CH_PEER_TLS_CA";
peer lifecycle chaincode install cvnd-token_1.tar.gz || true;

# Install on Supplier
setPeerEnv SupplierMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp peer0.supplier.kindledger.com:7051 "$SP_PEER_TLS_CA";
peer lifecycle chaincode install cvnd-token_1.tar.gz || true;

# Install on Auditor
setPeerEnv AuditorMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp peer0.auditor.kindledger.com:7051 "$AU_PEER_TLS_CA";
peer lifecycle chaincode install cvnd-token_1.tar.gz || true;

echo "== queryinstalled (using MBBank to get PKG_ID)";
setPeerEnv MBBankMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp peer0.mb.kindledger.com:7051 "$MB_PEER_TLS_CA";
PKG_ID=$(peer lifecycle chaincode queryinstalled | sed -n "s/Package ID: \(.*\), Label: cvnd-token_1/\1/p" | head -1);
echo "PKG_ID=$PKG_ID";

# Approve for all orgs
for ORG in MBBankMSP CharityMSP SupplierMSP AuditorMSP; do
  echo "== approve for $ORG";
  case $ORG in
    MBBankMSP)
      setPeerEnv MBBankMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp peer0.mb.kindledger.com:7051 "$MB_PEER_TLS_CA";;
    CharityMSP)
      setPeerEnv CharityMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/charity.kindledger.com/users/Admin@charity.kindledger.com/msp peer0.charity.kindledger.com:7051 "$CH_PEER_TLS_CA";;
    SupplierMSP)
      setPeerEnv SupplierMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/users/Admin@supplier.kindledger.com/msp peer0.supplier.kindledger.com:7051 "$SP_PEER_TLS_CA";;
    AuditorMSP)
      setPeerEnv AuditorMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/users/Admin@auditor.kindledger.com/msp peer0.auditor.kindledger.com:7051 "$AU_PEER_TLS_CA";;
  esac
  peer lifecycle chaincode approveformyorg \
    --channelID kindchannel --name cvnd-token --version 1 --sequence 1 \
    --package-id ${PKG_ID} \
    --tls --cafile "$ORDERER_TLS_CA" \
    --orderer orderer:7050 \
    --ordererTLSHostnameOverride orderer.orderer.kindledger.com || true;
  sleep 1;
done

echo "== checkcommitreadiness";
peer lifecycle chaincode checkcommitreadiness \
  --channelID kindchannel --name cvnd-token --version 1 --sequence 1 \
  --output json || true;

echo "== commit";
# Use multiple peer addresses for commit
setPeerEnv MBBankMSP /opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp peer0.mb.kindledger.com:7051 "$MB_PEER_TLS_CA";
peer lifecycle chaincode commit \
  --channelID kindchannel --name cvnd-token --version 1 --sequence 1 \
  --tls --cafile "$ORDERER_TLS_CA" \
  --orderer orderer:7050 \
  --ordererTLSHostnameOverride orderer.orderer.kindledger.com \
  --peerAddresses peer0.mb.kindledger.com:7051 --tlsRootCertFiles "$MB_PEER_TLS_CA" \
  --peerAddresses peer0.charity.kindledger.com:7051 --tlsRootCertFiles "$CH_PEER_TLS_CA" \
  --peerAddresses peer0.supplier.kindledger.com:7051 --tlsRootCertFiles "$SP_PEER_TLS_CA" \
  --peerAddresses peer0.auditor.kindledger.com:7051 --tlsRootCertFiles "$AU_PEER_TLS_CA" || true;

echo "== querycommitted";
peer lifecycle chaincode querycommitted --channelID kindchannel;
'

echo "[cvnd-token] Deploy completed."


