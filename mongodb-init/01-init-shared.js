// MongoDB initialization script for shared database
db = db.getSiblingDB('kindledger_shared');

// Create collections
db.createCollection('transactions');
db.createCollection('blocks');
db.createCollection('campaigns');
db.createCollection('users');
db.createCollection('audit_logs');

// Create indexes for better performance
db.transactions.createIndex({ "txHash": 1 }, { unique: true });
db.transactions.createIndex({ "timestamp": 1 });
db.transactions.createIndex({ "from": 1 });
db.transactions.createIndex({ "to": 1 });
db.transactions.createIndex({ "type": 1 });

db.blocks.createIndex({ "blockNumber": 1 }, { unique: true });
db.blocks.createIndex({ "timestamp": 1 });

db.campaigns.createIndex({ "campaignId": 1 }, { unique: true });
db.campaigns.createIndex({ "status": 1 });
db.campaigns.createIndex({ "createdAt": 1 });

db.users.createIndex({ "wallet": 1 }, { unique: true });
db.users.createIndex({ "kycStatus": 1 });

db.audit_logs.createIndex({ "timestamp": 1 });
db.audit_logs.createIndex({ "action": 1 });

// Insert initial data
db.transactions.insertOne({
  txHash: "0x0000000000000000000000000000000000000000",
  type: "genesis",
  amount: "0",
  timestamp: new Date(),
  from: "0x0000000000000000000000000000000000000000",
  to: "0x0000000000000000000000000000000000000000",
  status: "confirmed"
});

db.blocks.insertOne({
  blockNumber: 0,
  hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  timestamp: new Date(),
  transactions: 1,
  size: "0"
});

print("MongoDB shared database initialized successfully!");
