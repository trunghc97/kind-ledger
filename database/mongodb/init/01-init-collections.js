// Kind-Ledger MongoDB Collections
// MongoDB initialization script

// Switch to kindledger database
db = db.getSiblingDB('kindledger');

// NOTE: MongoDB chỉ dùng cho Explorer (blocks, transactions_ledger, chaincode_events)

db.createCollection('blocks', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["number"],
      properties: {
        number: { bsonType: "number" },
        blockHash: { bsonType: "string" },
        previousHash: { bsonType: "string" },
        transactionCount: { bsonType: "number" },
        ts: { bsonType: ["date", "null"] }
      }
    }
  }
});

db.createCollection('transactions_ledger', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["txId"],
      properties: {
        txId: { bsonType: "string" },
        status: { bsonType: "string" },
        validationCode: { bsonType: ["string", "number"] },
        chaincodeId: { bsonType: ["string", "null"] },
        blockNumber: { bsonType: "number" }
      }
    }
  }
});

db.createCollection('chaincode_events', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["txId", "eventName"],
      properties: {
        txId: { bsonType: "string" },
        chaincodeId: { bsonType: ["string", "null"] },
        eventName: { bsonType: "string" },
        payload: { bsonType: ["string", "null"] },
        blockNumber: { bsonType: "number" }
      }
    }
  }
});

db.blocks.createIndex({ number: 1 }, { unique: true });
db.transactions_ledger.createIndex({ txId: 1 }, { unique: true });
db.transactions_ledger.createIndex({ blockNumber: 1 });
db.chaincode_events.createIndex({ txId: 1 });

print("MongoDB explorer collections created successfully!");
