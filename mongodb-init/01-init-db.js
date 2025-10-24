// KindLedger MongoDB Initialization Script

// Switch to kindledger database
db = db.getSiblingDB('kindledger');

// Create collections with validation
db.createCollection('evidence', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["campaignId", "fileHash", "fileName"],
      properties: {
        campaignId: {
          bsonType: "int",
          description: "Campaign ID must be an integer"
        },
        fileHash: {
          bsonType: "string",
          description: "File hash must be a string"
        },
        fileName: {
          bsonType: "string",
          description: "File name must be a string"
        },
        fileSize: {
          bsonType: "long",
          description: "File size must be a number"
        },
        mimeType: {
          bsonType: "string",
          description: "MIME type must be a string"
        },
        ipfsUrl: {
          bsonType: "string",
          description: "IPFS URL must be a string"
        },
        createdAt: {
          bsonType: "date",
          description: "Created date must be a date"
        }
      }
    }
  }
});

db.createCollection('audit_logs', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["action", "userId", "timestamp"],
      properties: {
        action: {
          bsonType: "string",
          description: "Action must be a string"
        },
        userId: {
          bsonType: "string",
          description: "User ID must be a string"
        },
        timestamp: {
          bsonType: "date",
          description: "Timestamp must be a date"
        },
        details: {
          bsonType: "object",
          description: "Details must be an object"
        }
      }
    }
  }
});

// Create indexes for better performance
db.evidence.createIndex({ "campaignId": 1 });
db.evidence.createIndex({ "fileHash": 1 }, { unique: true });
db.evidence.createIndex({ "createdAt": -1 });

db.audit_logs.createIndex({ "userId": 1 });
db.audit_logs.createIndex({ "timestamp": -1 });
db.audit_logs.createIndex({ "action": 1 });

// Insert sample evidence data
db.evidence.insertMany([
  {
    campaignId: 1,
    fileHash: "QmSampleHash1",
    fileName: "campaign_1_evidence.pdf",
    fileSize: 1024000,
    mimeType: "application/pdf",
    ipfsUrl: "https://ipfs.io/ipfs/QmSampleHash1",
    createdAt: new Date()
  },
  {
    campaignId: 2,
    fileHash: "QmSampleHash2",
    fileName: "campaign_2_evidence.jpg",
    fileSize: 512000,
    mimeType: "image/jpeg",
    ipfsUrl: "https://ipfs.io/ipfs/QmSampleHash2",
    createdAt: new Date()
  }
]);

// Insert sample audit logs
db.audit_logs.insertMany([
  {
    action: "CAMPAIGN_CREATED",
    userId: "0x627306090abaB3A6e1400e9345bC60c78a8BEf57",
    timestamp: new Date(),
    details: {
      campaignId: 1,
      campaignName: "Ủng hộ trẻ em nghèo"
    }
  },
  {
    action: "DONATION_RECEIVED",
    userId: "0xf17f52151EbEF6C7334FAD080c5704D77216b732",
    timestamp: new Date(),
    details: {
      amount: 100000,
      campaignId: 1
    }
  }
]);

print("MongoDB initialization completed successfully!");
