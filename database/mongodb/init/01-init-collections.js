// Kind-Ledger MongoDB Collections
// MongoDB initialization script

// Switch to kindledger database
db = db.getSiblingDB('kindledger');

// Create collections with validation
db.createCollection('campaigns', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id", "name", "owner", "goal"],
      properties: {
        id: {
          bsonType: "string",
          description: "Campaign ID must be a string and is required"
        },
        name: {
          bsonType: "string",
          description: "Campaign name must be a string and is required"
        },
        description: {
          bsonType: "string",
          description: "Campaign description must be a string"
        },
        owner: {
          bsonType: "string",
          description: "Campaign owner must be a string and is required"
        },
        goal: {
          bsonType: "number",
          description: "Campaign goal must be a number and is required"
        },
        raised: {
          bsonType: "number",
          description: "Amount raised must be a number"
        },
        status: {
          bsonType: "string",
          enum: ["OPEN", "COMPLETED", "CANCELLED", "EXPIRED"],
          description: "Status must be one of the enum values"
        },
        createdAt: {
          bsonType: "date",
          description: "Created date must be a date"
        },
        updatedAt: {
          bsonType: "date",
          description: "Updated date must be a date"
        },
        metadata: {
          bsonType: "object",
          description: "Additional metadata as object"
        }
      }
    }
  }
});

db.createCollection('donations', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["campaignId", "donorId", "donorName", "amount"],
      properties: {
        campaignId: {
          bsonType: "string",
          description: "Campaign ID must be a string and is required"
        },
        donorId: {
          bsonType: "string",
          description: "Donor ID must be a string and is required"
        },
        donorName: {
          bsonType: "string",
          description: "Donor name must be a string and is required"
        },
        amount: {
          bsonType: "number",
          description: "Donation amount must be a number and is required"
        },
        transactionId: {
          bsonType: "string",
          description: "Transaction ID must be a string"
        },
        status: {
          bsonType: "string",
          enum: ["PENDING", "COMPLETED", "FAILED", "CANCELLED"],
          description: "Status must be one of the enum values"
        },
        createdAt: {
          bsonType: "date",
          description: "Created date must be a date"
        },
        metadata: {
          bsonType: "object",
          description: "Additional metadata as object"
        }
      }
    }
  }
});

db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "email", "passwordHash"],
      properties: {
        username: {
          bsonType: "string",
          description: "Username must be a string and is required"
        },
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
          description: "Email must be a valid email address"
        },
        passwordHash: {
          bsonType: "string",
          description: "Password hash must be a string and is required"
        },
        fullName: {
          bsonType: "string",
          description: "Full name must be a string"
        },
        organization: {
          bsonType: "string",
          description: "Organization must be a string"
        },
        role: {
          bsonType: "string",
          enum: ["ADMIN", "CHARITY_MANAGER", "SUPPLIER_MANAGER", "AUDITOR", "USER"],
          description: "Role must be one of the enum values"
        },
        status: {
          bsonType: "string",
          enum: ["ACTIVE", "INACTIVE", "SUSPENDED"],
          description: "Status must be one of the enum values"
        },
        createdAt: {
          bsonType: "date",
          description: "Created date must be a date"
        },
        lastLogin: {
          bsonType: "date",
          description: "Last login must be a date"
        },
        metadata: {
          bsonType: "object",
          description: "Additional metadata as object"
        }
      }
    }
  }
});

db.createCollection('transactions', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["transactionId", "type"],
      properties: {
        transactionId: {
          bsonType: "string",
          description: "Transaction ID must be a string and is required"
        },
        campaignId: {
          bsonType: "string",
          description: "Campaign ID must be a string"
        },
        donorId: {
          bsonType: "string",
          description: "Donor ID must be a string"
        },
        type: {
          bsonType: "string",
          enum: ["CREATE_CAMPAIGN", "DONATE", "QUERY_CAMPAIGN", "UPDATE_CAMPAIGN"],
          description: "Transaction type must be one of the enum values"
        },
        status: {
          bsonType: "string",
          enum: ["PENDING", "COMPLETED", "FAILED", "CANCELLED"],
          description: "Status must be one of the enum values"
        },
        amount: {
          bsonType: "number",
          description: "Transaction amount must be a number"
        },
        blockNumber: {
          bsonType: "number",
          description: "Block number must be a number"
        },
        blockHash: {
          bsonType: "string",
          description: "Block hash must be a string"
        },
        createdAt: {
          bsonType: "date",
          description: "Created date must be a date"
        },
        metadata: {
          bsonType: "object",
          description: "Additional metadata as object"
        }
      }
    }
  }
});

db.createCollection('organizations', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "domain", "mspId", "type"],
      properties: {
        name: {
          bsonType: "string",
          description: "Organization name must be a string and is required"
        },
        domain: {
          bsonType: "string",
          description: "Domain must be a string and is required"
        },
        mspId: {
          bsonType: "string",
          description: "MSP ID must be a string and is required"
        },
        type: {
          bsonType: "string",
          enum: ["BANK", "CHARITY", "SUPPLIER", "AUDITOR"],
          description: "Type must be one of the enum values"
        },
        status: {
          bsonType: "string",
          enum: ["ACTIVE", "INACTIVE", "SUSPENDED"],
          description: "Status must be one of the enum values"
        },
        createdAt: {
          bsonType: "date",
          description: "Created date must be a date"
        },
        metadata: {
          bsonType: "object",
          description: "Additional metadata as object"
        }
      }
    }
  }
});

// Create indexes for better performance
db.campaigns.createIndex({ "id": 1 }, { unique: true });
db.campaigns.createIndex({ "status": 1 });
db.campaigns.createIndex({ "owner": 1 });
db.campaigns.createIndex({ "createdAt": -1 });
db.campaigns.createIndex({ "name": "text", "description": "text" });

db.donations.createIndex({ "campaignId": 1 });
db.donations.createIndex({ "donorId": 1 });
db.donations.createIndex({ "createdAt": -1 });
db.donations.createIndex({ "status": 1 });

db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "organization": 1 });
db.users.createIndex({ "role": 1 });

db.transactions.createIndex({ "transactionId": 1 }, { unique: true });
db.transactions.createIndex({ "campaignId": 1 });
db.transactions.createIndex({ "type": 1 });
db.transactions.createIndex({ "createdAt": -1 });
db.transactions.createIndex({ "blockNumber": 1 });

db.organizations.createIndex({ "domain": 1 }, { unique: true });
db.organizations.createIndex({ "mspId": 1 }, { unique: true });
db.organizations.createIndex({ "type": 1 });

// Insert sample data
db.organizations.insertMany([
  {
    name: "MBBank",
    domain: "mb.kindledger.com",
    mspId: "MBBankMSP",
    type: "BANK",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  },
  {
    name: "Charity Organization",
    domain: "charity.kindledger.com",
    mspId: "CharityMSP",
    type: "CHARITY",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  },
  {
    name: "Supplier Company",
    domain: "supplier.kindledger.com",
    mspId: "SupplierMSP",
    type: "SUPPLIER",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  },
  {
    name: "Auditor Agency",
    domain: "auditor.kindledger.com",
    mspId: "AuditorMSP",
    type: "AUDITOR",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  }
]);

db.users.insertMany([
  {
    username: "admin",
    email: "admin@kindledger.com",
    passwordHash: "$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi",
    fullName: "System Administrator",
    organization: "MBBank",
    role: "ADMIN",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  },
  {
    username: "charity1",
    email: "charity1@kindledger.com",
    passwordHash: "$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi",
    fullName: "Charity Manager",
    organization: "Charity Organization",
    role: "CHARITY_MANAGER",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  },
  {
    username: "supplier1",
    email: "supplier1@kindledger.com",
    passwordHash: "$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi",
    fullName: "Supplier Manager",
    organization: "Supplier Company",
    role: "SUPPLIER_MANAGER",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  },
  {
    username: "auditor1",
    email: "auditor1@kindledger.com",
    passwordHash: "$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi",
    fullName: "Auditor",
    organization: "Auditor Agency",
    role: "AUDITOR",
    status: "ACTIVE",
    createdAt: new Date(),
    metadata: {}
  }
]);

db.campaigns.insertMany([
  {
    id: "campaign-001",
    name: "Hỗ trợ trẻ em nghèo",
    description: "Quyên góp để hỗ trợ trẻ em có hoàn cảnh khó khăn",
    owner: "charity1@kindledger.com",
    goal: 10000000,
    raised: 0,
    status: "OPEN",
    createdAt: new Date(),
    updatedAt: new Date(),
    metadata: {
      category: "children",
      location: "Vietnam",
      targetBeneficiaries: 100
    }
  },
  {
    id: "campaign-002",
    name: "Xây dựng trường học",
    description: "Xây dựng trường học mới cho vùng sâu vùng xa",
    owner: "charity1@kindledger.com",
    goal: 50000000,
    raised: 0,
    status: "OPEN",
    createdAt: new Date(),
    updatedAt: new Date(),
    metadata: {
      category: "education",
      location: "Mountain areas",
      targetBeneficiaries: 500
    }
  },
  {
    id: "campaign-003",
    name: "Hỗ trợ người già",
    description: "Chăm sóc và hỗ trợ người già neo đơn",
    owner: "charity1@kindledger.com",
    goal: 20000000,
    raised: 0,
    status: "OPEN",
    createdAt: new Date(),
    updatedAt: new Date(),
    metadata: {
      category: "elderly",
      location: "Urban areas",
      targetBeneficiaries: 50
    }
  }
]);

print("MongoDB collections and sample data created successfully!");
