#!/bin/bash

# Kind-Ledger Setup Script
# Tạo các thư mục và file cần thiết trước khi chạy docker-compose

echo "Setting up Kind-Ledger directories..."

# Tạo thư mục blockchain
mkdir -p blockchain/artifacts
mkdir -p blockchain/crypto-config

# Tạo cấu trúc crypto-config
mkdir -p blockchain/crypto-config/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/msp
mkdir -p blockchain/crypto-config/ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com/tls
mkdir -p blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/msp
mkdir -p blockchain/crypto-config/peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com/tls
mkdir -p blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/msp
mkdir -p blockchain/crypto-config/peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com/tls
mkdir -p blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/msp
mkdir -p blockchain/crypto-config/peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com/tls
mkdir -p blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/msp
mkdir -p blockchain/crypto-config/peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com/tls

# Tạo placeholder certificates
for org in ordererOrganizations/kindledger.com/orderers/orderer.kindledger.com peerOrganizations/mb.kindledger.com/peers/peer0.mb.kindledger.com peerOrganizations/charity.kindledger.com/peers/peer0.charity.kindledger.com peerOrganizations/supplier.kindledger.com/peers/peer0.supplier.kindledger.com peerOrganizations/auditor.kindledger.com/peers/peer0.auditor.kindledger.com; do
    mkdir -p blockchain/crypto-config/$org/msp/{admincerts,cacerts,keystore,signcerts}
    mkdir -p blockchain/crypto-config/$org/tls
    touch blockchain/crypto-config/$org/msp/admincerts/cert.pem
    touch blockchain/crypto-config/$org/msp/cacerts/ca.crt
    touch blockchain/crypto-config/$org/msp/keystore/key.pem
    touch blockchain/crypto-config/$org/msp/signcerts/cert.pem
    touch blockchain/crypto-config/$org/tls/{ca.crt,server.crt,server.key}
done

# Tạo placeholder genesis block
echo "# Placeholder genesis block" > blockchain/artifacts/genesis.block

# Tạo thư mục database
mkdir -p database/init
mkdir -p database/mongodb/init

# Tạo thư mục wallet
mkdir -p gateway/wallet
mkdir -p explorer/wallet

echo "Setup completed!"
echo "Now you can run: docker-compose up --build"
