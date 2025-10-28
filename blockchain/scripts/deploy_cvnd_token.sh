#!/bin/bash
set -euo pipefail

echo "[cvnd-token] Deploy starting..."

ORDERER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/ordererOrganizations/orderer.kindledger.com/msp/tlscacerts/tlsca.orderer.kindledger.com-cert.pem
MB_PEER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt

docker exec -e ORDERER_TLS_CA="$ORDERER_TLS_CA" -e MB_PEER_TLS_CA="$MB_PEER_TLS_CA" fabric-tools bash -lc '
set -e;
export FABRIC_CFG_PATH=/etc/hyperledger/fabric;
export CORE_PEER_LOCALMSPID=MBBankMSP;
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp;
export CORE_PEER_ADDRESS=peer0.mb.kindledger.com:7051;
export CORE_PEER_TLS_ENABLED=true;
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls/ca.crt;
cd /opt/gopath/src/github.com/hyperledger/fabric/peer;
echo "== go mod tidy";
cd blockchain/chaincode/cvnd-token && go mod tidy && cd - >/dev/null;
echo "== package";
rm -f cvnd-token_1.tar.gz;
peer lifecycle chaincode package cvnd-token_1.tar.gz --path blockchain/chaincode/cvnd-token --lang golang --label cvnd-token_1;
echo "== install (ignore if already installed)";
peer lifecycle chaincode install cvnd-token_1.tar.gz || true;
echo "== queryinstalled";
PKG_ID=$(peer lifecycle chaincode queryinstalled | sed -n "s/Package ID: \(.*\), Label: cvnd-token_1/\1/p" | head -1);
echo "PKG_ID=$PKG_ID";
echo "== approve (default policy)";
peer lifecycle chaincode approveformyorg \
  --channelID kindchannel --name cvnd-token --version 1 --sequence 1 \
  --package-id ${PKG_ID} \
  --tls --cafile '"$ORDERER_TLS_CA"' \
  --orderer orderer.kindledger.com:7050 \
  --ordererTLSHostnameOverride orderer.orderer.kindledger.com;
echo "== commit";
peer lifecycle chaincode commit \
  --channelID kindchannel --name cvnd-token --version 1 --sequence 1 \
  --tls --cafile '"$ORDERER_TLS_CA"' \
  --orderer orderer.kindledger.com:7050 \
  --ordererTLSHostnameOverride orderer.orderer.kindledger.com \
  --peerAddresses peer0.mb.kindledger.com:7051 \
  --tlsRootCertFiles '"$MB_PEER_TLS_CA"';
echo "== querycommitted";
peer lifecycle chaincode querycommitted --channelID kindchannel;
'

echo "[cvnd-token] Deploy completed."


