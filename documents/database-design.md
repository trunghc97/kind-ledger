# Thiết kế Database - KindLedger

## Mục lục

1. [Tổng quan Kiến trúc Database](#1-tổng-quan-kiến-trúc-database)
2. [PostgreSQL Schema](#2-postgresql-schema)
3. [MongoDB Collections](#3-mongodb-collections)
4. [Redis Cache Strategy](#4-redis-cache-strategy)
5. [Data Flow & Integration](#5-data-flow--integration)
6. [Performance Optimization](#6-performance-optimization)
7. [Backup & Recovery](#7-backup--recovery)
8. [Security & Access Control](#8-security--access-control)
9. [Monitoring & Maintenance](#9-monitoring--maintenance)

---

## 1. Tổng quan Kiến trúc Database

### 1.1 Multi-Database Architecture

KindLedger sử dụng kiến trúc multi-database để tối ưu hóa hiệu suất và linh hoạt:

```mermaid
graph TB
    subgraph "Application Layer"
        GW[API Gateway]
        FE[Frontend]
        EX[Explorer]
    end
    
    subgraph "Database Layer"
        PG[(PostgreSQL<br/>Structured Data)]
        MG[(MongoDB<br/>Document Store)]
        RD[(Redis<br/>Cache & Sessions)]
    end
    
    subgraph "Blockchain Layer"
        BC[Hyperledger Fabric]
    end
    
    GW --> PG
    GW --> MG
    GW --> RD
    GW --> BC
    
    FE --> GW
    EX --> GW
    
    PG -.-> MG
    MG -.-> RD
```

### 1.2 Database Roles

| Database | Purpose | Data Type | Use Cases |
|----------|---------|-----------|-----------|
| **PostgreSQL** | Primary OLTP | Structured, ACID | Campaigns, Users, Transactions |
| **MongoDB** | Analytics & Flexibility | Document, Flexible | Reports, Analytics, Metadata |
| **Redis** | Cache & Sessions | Key-Value, Fast | Sessions, Cache, Real-time data |

### 1.3 Data Distribution Strategy

```mermaid
flowchart LR
    API[API Request] --> Router{Data Type?}
    
    Router -->|Structured| PG[PostgreSQL]
    Router -->|Flexible| MG[MongoDB]
    Router -->|Cache| RD[Redis]
    
    PG --> Sync[Data Sync]
    MG --> Sync
    Sync --> BC[Blockchain]
    
    BC --> Audit[Audit Trail]
    Audit --> MG
```

---

## 2. PostgreSQL Schema

### 2.1 Core Tables

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('USER', 'ADMIN', 'CHARITY', 'SUPPLIER', 'AUDITOR')),
    organization_id UUID REFERENCES organizations(id),
    msp_id VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_organization ON users(organization_id);
CREATE INDEX idx_users_role ON users(role);
```

#### Organizations Table
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('BANK', 'CHARITY', 'SUPPLIER', 'AUDITOR')),
    msp_id VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_organizations_msp_id ON organizations(msp_id);
CREATE INDEX idx_organizations_type ON organizations(type);
```

#### Campaigns Table
```sql
CREATE TABLE campaigns (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL REFERENCES users(id),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    goal_amount DECIMAL(15,2) NOT NULL CHECK (goal_amount > 0),
    raised_amount DECIMAL(15,2) DEFAULT 0 CHECK (raised_amount >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' 
        CHECK (status IN ('OPEN', 'COMPLETED', 'CLOSED', 'DISBURSED')),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    blockchain_tx_hash VARCHAR(255),
    metadata JSONB
);

CREATE INDEX idx_campaigns_owner ON campaigns(owner_id);
CREATE INDEX idx_campaigns_organization ON campaigns(organization_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_created_at ON campaigns(created_at);
CREATE INDEX idx_campaigns_goal_amount ON campaigns(goal_amount);
CREATE INDEX idx_campaigns_metadata ON campaigns USING GIN(metadata);
```

#### Donations Table
```sql
CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id VARCHAR(100) NOT NULL REFERENCES campaigns(id),
    donor_id UUID REFERENCES users(id),
    donor_name VARCHAR(255),
    donor_email VARCHAR(255),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50),
    payment_reference VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'CONFIRMED', 'FAILED', 'REFUNDED')),
    donated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    blockchain_tx_hash VARCHAR(255),
    metadata JSONB,
    is_anonymous BOOLEAN DEFAULT false
);

CREATE INDEX idx_donations_campaign ON donations(campaign_id);
CREATE INDEX idx_donations_donor ON donations(donor_id);
CREATE INDEX idx_donations_amount ON donations(amount);
CREATE INDEX idx_donations_donated_at ON donations(donated_at);
CREATE INDEX idx_donations_status ON donations(status);
CREATE INDEX idx_donations_metadata ON donations USING GIN(metadata);
```

#### Transactions Table (Blockchain Audit)
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tx_hash VARCHAR(255) UNIQUE NOT NULL,
    block_number BIGINT,
    campaign_id VARCHAR(100) REFERENCES campaigns(id),
    transaction_type VARCHAR(50) NOT NULL 
        CHECK (transaction_type IN ('CREATE_CAMPAIGN', 'DONATE', 'DISBURSE', 'UPDATE_STATUS')),
    amount DECIMAL(15,2),
    from_address VARCHAR(255),
    to_address VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'CONFIRMED', 'FAILED')),
    gas_used BIGINT,
    gas_price DECIMAL(20,8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    raw_data JSONB
);

CREATE INDEX idx_transactions_tx_hash ON transactions(tx_hash);
CREATE INDEX idx_transactions_campaign ON transactions(campaign_id);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_raw_data ON transactions USING GIN(raw_data);
```

### 2.2 Views for Analytics

#### Campaign Summary View
```sql
CREATE VIEW campaign_summary AS
SELECT 
    c.id,
    c.name,
    c.goal_amount,
    c.raised_amount,
    c.status,
    c.created_at,
    COUNT(d.id) as donation_count,
    AVG(d.amount) as avg_donation,
    MAX(d.donated_at) as last_donation,
    ROUND((c.raised_amount / c.goal_amount * 100), 2) as progress_percentage
FROM campaigns c
LEFT JOIN donations d ON c.id = d.campaign_id AND d.status = 'CONFIRMED'
GROUP BY c.id, c.name, c.goal_amount, c.raised_amount, c.status, c.created_at;
```

#### Donor Statistics View
```sql
CREATE VIEW donor_statistics AS
SELECT 
    donor_id,
    donor_name,
    COUNT(*) as total_donations,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount,
    MIN(donated_at) as first_donation,
    MAX(donated_at) as last_donation,
    COUNT(DISTINCT campaign_id) as campaigns_supported
FROM donations 
WHERE status = 'CONFIRMED' AND donor_id IS NOT NULL
GROUP BY donor_id, donor_name;
```

### 2.3 Triggers for Data Consistency

#### Update Campaign Raised Amount
```sql
CREATE OR REPLACE FUNCTION update_campaign_raised_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'CONFIRMED' THEN
        UPDATE campaigns 
        SET raised_amount = raised_amount + NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.campaign_id;
        
        -- Check if goal is reached
        UPDATE campaigns 
        SET status = 'COMPLETED',
            updated_at = NOW()
        WHERE id = NEW.campaign_id 
        AND raised_amount >= goal_amount 
        AND status = 'OPEN';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_campaign_raised
    AFTER INSERT ON donations
    FOR EACH ROW
    EXECUTE FUNCTION update_campaign_raised_amount();
```

---

## 3. MongoDB Collections

### 3.1 Campaign Analytics Collection

```javascript
// campaigns_analytics collection
{
  _id: ObjectId,
  campaign_id: "campaign-001",
  name: "Support Poor Children",
  analytics: {
    total_views: 1250,
    unique_visitors: 890,
    conversion_rate: 12.5,
    avg_session_duration: 180, // seconds
    traffic_sources: {
      direct: 45,
      social: 30,
      search: 20,
      referral: 5
    },
    geographic_distribution: {
      "VN": 60,
      "US": 25,
      "SG": 10,
      "Other": 5
    }
  },
  social_metrics: {
    shares: 45,
    likes: 120,
    comments: 23
  },
  performance_metrics: {
    daily_donations: [
      { date: "2025-10-28", amount: 500000, count: 5 },
      { date: "2025-10-29", amount: 750000, count: 8 }
    ],
    hourly_patterns: {
      "09:00": 0.15,
      "12:00": 0.25,
      "18:00": 0.35,
      "21:00": 0.25
    }
  },
  created_at: ISODate,
  updated_at: ISODate
}
```

### 3.2 User Behavior Collection

```javascript
// user_behaviors collection
{
  _id: ObjectId,
  user_id: "user-123",
  session_id: "session-456",
  events: [
    {
      event_type: "page_view",
      page: "/campaigns/campaign-001",
      timestamp: ISODate,
      metadata: {
        referrer: "https://google.com",
        user_agent: "Mozilla/5.0...",
        ip_address: "192.168.1.1"
      }
    },
    {
      event_type: "donation_started",
      campaign_id: "campaign-001",
      amount: 500000,
      timestamp: ISODate
    },
    {
      event_type: "donation_completed",
      campaign_id: "campaign-001",
      amount: 500000,
      timestamp: ISODate,
      payment_method: "credit_card"
    }
  ],
  session_start: ISODate,
  session_end: ISODate,
  total_events: 5
}
```

### 3.3 System Logs Collection

```javascript
// system_logs collection
{
  _id: ObjectId,
  level: "INFO", // DEBUG, INFO, WARN, ERROR, FATAL
  service: "gateway",
  message: "Campaign created successfully",
  timestamp: ISODate,
  request_id: "req-123-456",
  user_id: "user-123",
  organization_id: "org-456",
  metadata: {
    campaign_id: "campaign-001",
    amount: 1000000,
    processing_time_ms: 250
  },
  stack_trace: "...", // Only for ERROR/FATAL
  environment: "production"
}
```

### 3.4 MongoDB Indexes

```javascript
// Create indexes for performance
db.campaigns_analytics.createIndex({ "campaign_id": 1 })
db.campaigns_analytics.createIndex({ "created_at": 1 })
db.campaigns_analytics.createIndex({ "analytics.total_views": 1 })

db.user_behaviors.createIndex({ "user_id": 1, "timestamp": 1 })
db.user_behaviors.createIndex({ "session_id": 1 })
db.user_behaviors.createIndex({ "events.event_type": 1 })

db.system_logs.createIndex({ "level": 1, "timestamp": 1 })
db.system_logs.createIndex({ "service": 1, "timestamp": 1 })
db.system_logs.createIndex({ "request_id": 1 })
db.system_logs.createIndex({ "timestamp": 1 }, { expireAfterSeconds: 2592000 }) // 30 days TTL
```

### 3.5 Ledger Collections (Đồng bộ từ Blockchain - Read Only)

Các collection dưới đây được Explorer đồng bộ trực tiếp từ Hyperledger Fabric. Dữ liệu bất biến (append-only) và chỉ được ghi bởi listener từ Fabric. Ứng dụng khác chỉ được đọc.

- blocks
  - Fields: number (unique), blockHash, previousHash, transactionCount, ts
  - Indexes: { number: 1 } (unique)
- transactions_ledger
  - Fields: txId (unique), status, validationCode, chaincodeId, blockNumber
  - Indexes: { txId: 1 } (unique), { blockNumber: 1 }
- chaincode_events
  - Fields: txId, chaincodeId, eventName, payload, blockNumber
  - Indexes: { txId: 1 }, { eventName: 1, blockNumber: -1 }

Quy tắc bất biến và nhất quán:
- Không có API nào ghi vào 3 collection này ngoài Explorer listener.
- Ghi idempotent: upsert block theo number; insertMany với ordered=false để bỏ qua trùng lặp.
- Không hỗ trợ cập nhật/xóa.
- Mỗi txId trong chaincode_events phải tồn tại trong transactions_ledger cùng blockNumber.

Truy vấn mẫu (đọc-an-toàn):
```javascript
// Chiều cao chuỗi khối (height)
const last = db.blocks.find().sort({ number: -1 }).limit(1).toArray();
const height = last.length ? last[0].number + 1 : 0;

// 10 block gần nhất
db.blocks.find().sort({ number: -1 }).limit(10)

// Giao dịch theo txId
db.transactions_ledger.findOne({ txId: "<TX_ID>" })

// Sự kiện Mint mới nhất
db.chaincode_events.find({ eventName: "Mint" }).sort({ blockNumber: -1 }).limit(5)

// Kiểm tra chéo sự kiện có tx tương ứng
db.chaincode_events.aggregate([
  { $lookup: { from: "transactions_ledger", localField: "txId", foreignField: "txId", as: "tx" } },
  { $match: { tx: { $size: 0 } } }
])
```

---

## 4. Redis Cache Strategy

### 4.1 Cache Keys Structure

```
# Session Management
session:{session_id} -> {user_data, permissions, expires}
user:{user_id}:session -> {session_id, last_activity}

# Campaign Data
campaign:{campaign_id} -> {campaign_data, expires}
campaigns:list:{page}:{limit} -> {campaigns_list, expires}
campaign:{campaign_id}:donors -> {donors_list, expires}

# Statistics
stats:total_donations -> {total_amount, last_updated}
stats:daily:{date} -> {daily_stats, expires}
stats:campaign:{campaign_id} -> {campaign_stats, expires}

# Rate Limiting
rate_limit:{ip}:{endpoint} -> {count, window_start}
rate_limit:{user_id}:{action} -> {count, window_start}

# Real-time Data
realtime:donations -> {recent_donations}
realtime:campaign:{campaign_id}:progress -> {progress_data}
```

### 4.2 Cache Implementation

#### Session Cache
```python
# Session management with Redis
def create_session(user_id, permissions):
    session_id = generate_session_id()
    session_data = {
        'user_id': user_id,
        'permissions': permissions,
        'created_at': datetime.utcnow().isoformat(),
        'last_activity': datetime.utcnow().isoformat()
    }
    
    # Store session with 24h expiry
    redis_client.setex(
        f"session:{session_id}", 
        86400, 
        json.dumps(session_data)
    )
    
    # Track user sessions
    redis_client.setex(
        f"user:{user_id}:session", 
        86400, 
        session_id
    )
    
    return session_id

def get_session(session_id):
    session_data = redis_client.get(f"session:{session_id}")
    if session_data:
        return json.loads(session_data)
    return None
```

#### Campaign Cache
```python
# Campaign data caching
def get_campaign(campaign_id, use_cache=True):
    if use_cache:
        cached = redis_client.get(f"campaign:{campaign_id}")
        if cached:
            return json.loads(cached)
    
    # Fetch from database
    campaign = db.get_campaign(campaign_id)
    
    if campaign:
        # Cache for 5 minutes
        redis_client.setex(
            f"campaign:{campaign_id}", 
            300, 
            json.dumps(campaign)
        )
    
    return campaign

def invalidate_campaign_cache(campaign_id):
    redis_client.delete(f"campaign:{campaign_id}")
    redis_client.delete(f"campaign:{campaign_id}:donors")
    # Invalidate campaigns list cache
    redis_client.delete_pattern("campaigns:list:*")
```

#### Statistics Cache
```python
# Statistics caching with background refresh
def get_total_donations():
    cached = redis_client.get("stats:total_donations")
    if cached:
        data = json.loads(cached)
        # Refresh if older than 1 hour
        if datetime.utcnow() - datetime.fromisoformat(data['last_updated']) < timedelta(hours=1):
            return data['total_amount']
    
    # Calculate from database
    total = db.calculate_total_donations()
    
    # Cache for 1 hour
    cache_data = {
        'total_amount': total,
        'last_updated': datetime.utcnow().isoformat()
    }
    redis_client.setex(
        "stats:total_donations", 
        3600, 
        json.dumps(cache_data)
    )
    
    return total
```

### 4.3 Cache Invalidation Strategy

```python
# Cache invalidation patterns
def invalidate_campaign_related_cache(campaign_id):
    """Invalidate all cache related to a campaign"""
    patterns = [
        f"campaign:{campaign_id}",
        f"campaign:{campaign_id}:donors",
        f"campaign:{campaign_id}:stats",
        "campaigns:list:*",
        "stats:total_donations",
        "stats:daily:*"
    ]
    
    for pattern in patterns:
        if "*" in pattern:
            redis_client.delete_pattern(pattern)
        else:
            redis_client.delete(pattern)

def invalidate_user_related_cache(user_id):
    """Invalidate cache related to a user"""
    patterns = [
        f"user:{user_id}:session",
        f"user:{user_id}:donations",
        f"user:{user_id}:campaigns"
    ]
    
    for pattern in patterns:
        redis_client.delete(pattern)
```

---

## 5. Data Flow & Integration

### 5.1 Data Synchronization Flow

```mermaid
sequenceDiagram
    participant API as API Gateway
    participant PG as PostgreSQL
    participant MG as MongoDB
    participant RD as Redis
    participant BC as Blockchain
    
    API->>PG: Write transaction
    PG-->>API: Confirm write
    
    API->>BC: Submit to blockchain
    BC-->>API: Transaction hash
    
    API->>PG: Update with tx_hash
    API->>RD: Invalidate cache
    
    par Async Sync
        API->>MG: Sync analytics data
    and
        API->>RD: Update real-time cache
    end
    
    MG-->>API: Sync complete
    RD-->>API: Cache updated
```

### 5.2 Data Consistency Strategy

#### Eventual Consistency Model
```python
class DataConsistencyManager:
    def __init__(self):
        self.postgres = PostgreSQLClient()
        self.mongodb = MongoDBClient()
        self.redis = RedisClient()
        self.blockchain = BlockchainClient()
    
    async def create_campaign(self, campaign_data):
        # 1. Write to PostgreSQL (primary)
        campaign = await self.postgres.create_campaign(campaign_data)
        
        # 2. Submit to blockchain
        tx_hash = await self.blockchain.create_campaign(campaign)
        
        # 3. Update PostgreSQL with tx_hash
        await self.postgres.update_campaign_tx_hash(campaign.id, tx_hash)
        
        # 4. Invalidate cache
        await self.redis.invalidate_campaign_cache(campaign.id)
        
        # 5. Async sync to MongoDB
        asyncio.create_task(self.sync_to_mongodb(campaign))
        
        return campaign
    
    async def sync_to_mongodb(self, campaign):
        """Async sync campaign data to MongoDB"""
        try:
            await self.mongodb.upsert_campaign_analytics(campaign)
        except Exception as e:
            # Log error and retry later
            logger.error(f"Failed to sync campaign {campaign.id} to MongoDB: {e}")
            await self.schedule_retry(campaign.id)
```

### 5.3 Data Migration Strategy

#### Version Control for Schema Changes
```sql
-- Migration: Add campaign categories
-- Version: 2025.10.28.001

-- Add category column
ALTER TABLE campaigns ADD COLUMN category VARCHAR(50);

-- Create category lookup table
CREATE TABLE campaign_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO campaign_categories (name, description) VALUES
('EDUCATION', 'Educational programs and scholarships'),
('HEALTHCARE', 'Medical assistance and healthcare'),
('DISASTER_RELIEF', 'Emergency disaster response'),
('ENVIRONMENT', 'Environmental protection and conservation'),
('SOCIAL_WELFARE', 'Social welfare and community support');

-- Add foreign key constraint
ALTER TABLE campaigns ADD CONSTRAINT fk_campaigns_category 
    FOREIGN KEY (category) REFERENCES campaign_categories(name);

-- Create index
CREATE INDEX idx_campaigns_category ON campaigns(category);
```

---

## 6. Performance Optimization

### 6.1 Database Indexing Strategy

#### PostgreSQL Indexes
```sql
-- Composite indexes for common queries
CREATE INDEX idx_donations_campaign_status_amount 
    ON donations(campaign_id, status, amount);

CREATE INDEX idx_campaigns_status_created 
    ON campaigns(status, created_at DESC);

CREATE INDEX idx_transactions_campaign_type_status 
    ON transactions(campaign_id, transaction_type, status);

-- Partial indexes for active data
CREATE INDEX idx_active_campaigns 
    ON campaigns(created_at DESC) 
    WHERE status IN ('OPEN', 'COMPLETED');

-- Covering indexes
CREATE INDEX idx_campaigns_covering 
    ON campaigns(id, name, status, goal_amount, raised_amount);
```

#### MongoDB Indexes
```javascript
// Compound indexes for analytics queries
db.campaigns_analytics.createIndex({
    "campaign_id": 1,
    "created_at": -1
})

// Text search index
db.campaigns_analytics.createIndex({
    "name": "text",
    "description": "text"
})

// TTL index for automatic cleanup
db.system_logs.createIndex(
    { "timestamp": 1 }, 
    { expireAfterSeconds: 2592000 } // 30 days
)
```

### 6.2 Query Optimization

#### Optimized Campaign Queries
```sql
-- Efficient campaign listing with pagination
SELECT 
    c.id,
    c.name,
    c.goal_amount,
    c.raised_amount,
    c.status,
    c.created_at,
    COUNT(d.id) as donation_count,
    ROUND((c.raised_amount / c.goal_amount * 100), 2) as progress
FROM campaigns c
LEFT JOIN donations d ON c.id = d.campaign_id AND d.status = 'CONFIRMED'
WHERE c.status = 'OPEN'
GROUP BY c.id, c.name, c.goal_amount, c.raised_amount, c.status, c.created_at
ORDER BY c.created_at DESC
LIMIT 20 OFFSET 0;

-- Use EXPLAIN ANALYZE to verify performance
EXPLAIN ANALYZE SELECT ...;
```

#### MongoDB Aggregation Pipelines
```javascript
// Optimized analytics aggregation
db.campaigns_analytics.aggregate([
    {
        $match: {
            created_at: {
                $gte: new Date("2025-10-01"),
                $lt: new Date("2025-11-01")
            }
        }
    },
    {
        $group: {
            _id: "$campaign_id",
            total_views: { $sum: "$analytics.total_views" },
            total_donations: { $sum: "$analytics.total_donations" },
            avg_conversion: { $avg: "$analytics.conversion_rate" }
        }
    },
    {
        $sort: { total_views: -1 }
    },
    {
        $limit: 10
    }
])
```

### 6.3 Connection Pooling

#### PostgreSQL Connection Pool
```yaml
# application.yml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/kindledger
    username: kindledger
    password: kindledger123
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      leak-detection-threshold: 60000
```

#### MongoDB Connection Pool
```yaml
spring:
  data:
    mongodb:
      uri: mongodb://kindledger:kindledger123@localhost:27017/kindledger
      options:
        max-connections-per-host: 100
        threads-allowed-to-block-for-connection-multiplier: 5
        server-selection-timeout: 30000
        max-wait-time: 120000
        max-connection-idle-time: 0
        max-connection-life-time: 0
```

---

## 7. Backup & Recovery

### 7.1 Backup Strategy

#### Automated Backup Script
```bash
#!/bin/bash
# backup-databases.sh

BACKUP_DIR="/backups/kindledger"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR/$DATE

# PostgreSQL backup
echo "Backing up PostgreSQL..."
docker exec kindledger-postgres pg_dump -U kindledger -d kindledger \
    --format=custom --compress=9 \
    --file=/backups/kindledger_$DATE.dump

# MongoDB backup
echo "Backing up MongoDB..."
docker exec kindledger-mongodb mongodump \
    --username kindledger --password kindledger123 \
    --authenticationDatabase kindledger \
    --db kindledger \
    --out /backups/mongodb_$DATE

# Redis backup (RDB snapshot)
echo "Backing up Redis..."
docker exec kindledger-redis redis-cli -a kindledger123 BGSAVE
docker cp kindledger-redis:/data/dump.rdb $BACKUP_DIR/$DATE/redis_dump.rdb

# Compress backups
tar -czf $BACKUP_DIR/kindledger_backup_$DATE.tar.gz -C $BACKUP_DIR $DATE

# Clean old backups
find $BACKUP_DIR -name "kindledger_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: kindledger_backup_$DATE.tar.gz"
```

#### Cron Job Setup
```bash
# Add to crontab
# Daily backup at 2 AM
0 2 * * * /opt/kindledger/scripts/backup-databases.sh

# Weekly full backup on Sunday at 1 AM
0 1 * * 0 /opt/kindledger/scripts/backup-databases.sh --full

# Monthly archive backup
0 0 1 * * /opt/kindledger/scripts/backup-databases.sh --archive
```

### 7.2 Recovery Procedures

#### PostgreSQL Recovery
```bash
# Restore PostgreSQL from backup
docker exec -i kindledger-postgres pg_restore \
    -U kindledger -d kindledger \
    --clean --if-exists \
    /backups/kindledger_20251028_020000.dump

# Point-in-time recovery (if WAL archiving enabled)
docker exec kindledger-postgres pg_basebackup \
    -D /var/lib/postgresql/data/recovery \
    -Ft -z -P -U kindledger
```

#### MongoDB Recovery
```bash
# Restore MongoDB from backup
docker exec kindledger-mongodb mongorestore \
    --username kindledger --password kindledger123 \
    --authenticationDatabase kindledger \
    --db kindledger \
    /backups/mongodb_20251028_020000/kindledger

# Restore specific collection
docker exec kindledger-mongodb mongorestore \
    --username kindledger --password kindledger123 \
    --authenticationDatabase kindledger \
    --db kindledger \
    --collection campaigns_analytics \
    /backups/mongodb_20251028_020000/kindledger/campaigns_analytics.bson
```

### 7.3 Disaster Recovery Plan

#### RTO/RPO Targets
- **RTO (Recovery Time Objective)**: 4 hours
- **RPO (Recovery Point Objective)**: 1 hour

#### Recovery Procedures
```mermaid
flowchart TD
    Detect[Detect Disaster] --> Assess[Assess Damage]
    Assess --> Decision{Data Loss?}
    
    Decision -->|No| Restart[Restart Services]
    Decision -->|Yes| Restore[Restore from Backup]
    
    Restore --> Validate[Validate Data Integrity]
    Validate --> Sync[Sync with Blockchain]
    Sync --> Test[Test System]
    
    Restart --> Test
    Test --> GoLive[Go Live]
    
    GoLive --> Monitor[Monitor System]
```

---

## 8. Security & Access Control

### 8.1 Database Security

#### PostgreSQL Security
```sql
-- Create application user with limited privileges
CREATE USER kindledger_app WITH PASSWORD 'secure_password_123';

-- Grant only necessary permissions
GRANT CONNECT ON DATABASE kindledger TO kindledger_app;
GRANT USAGE ON SCHEMA public TO kindledger_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO kindledger_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO kindledger_app;

-- Create read-only user for reporting
CREATE USER kindledger_readonly WITH PASSWORD 'readonly_password_456';
GRANT CONNECT ON DATABASE kindledger TO kindledger_readonly;
GRANT USAGE ON SCHEMA public TO kindledger_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO kindledger_readonly;

-- Enable row-level security
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY campaign_access_policy ON campaigns
    FOR ALL TO kindledger_app
    USING (true);

CREATE POLICY donation_access_policy ON donations
    FOR ALL TO kindledger_app
    USING (true);
```

#### MongoDB Security
```javascript
// Create application user
use kindledger
db.createUser({
    user: "kindledger_app",
    pwd: "secure_password_123",
    roles: [
        { role: "readWrite", db: "kindledger" }
    ]
})

// Create read-only user
db.createUser({
    user: "kindledger_readonly",
    pwd: "readonly_password_456",
    roles: [
        { role: "read", db: "kindledger" }
    ]
})

// Enable authentication
use admin
db.createUser({
    user: "admin",
    pwd: "admin_password_789",
    roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
})
```

### 8.2 Data Encryption

#### Encryption at Rest
```yaml
# PostgreSQL encryption configuration
postgresql:
  ssl: true
  ssl_cert_file: /etc/ssl/certs/server.crt
  ssl_key_file: /etc/ssl/private/server.key
  ssl_ca_file: /etc/ssl/certs/ca.crt

# MongoDB encryption
mongodb:
  encryption:
    key_file: /etc/mongodb/encryption.key
    enable_encryption: true
```

#### Encryption in Transit
```python
# Application-level encryption for sensitive data
from cryptography.fernet import Fernet

class DataEncryption:
    def __init__(self, key):
        self.cipher = Fernet(key)
    
    def encrypt_sensitive_data(self, data):
        """Encrypt sensitive fields before storing"""
        if isinstance(data, dict):
            encrypted_data = data.copy()
            sensitive_fields = ['email', 'phone', 'address']
            
            for field in sensitive_fields:
                if field in encrypted_data:
                    encrypted_data[field] = self.cipher.encrypt(
                        encrypted_data[field].encode()
                    ).decode()
            
            return encrypted_data
        return data
    
    def decrypt_sensitive_data(self, data):
        """Decrypt sensitive fields when retrieving"""
        if isinstance(data, dict):
            decrypted_data = data.copy()
            sensitive_fields = ['email', 'phone', 'address']
            
            for field in sensitive_fields:
                if field in decrypted_data:
                    decrypted_data[field] = self.cipher.decrypt(
                        decrypted_data[field].encode()
                    ).decode()
            
            return decrypted_data
        return data
```

### 8.3 Access Control Matrix

| Role | PostgreSQL | MongoDB | Redis | Blockchain |
|------|------------|---------|-------|------------|
| **Admin** | Full Access | Full Access | Full Access | Full Access |
| **Charity** | Read/Write Campaigns | Read/Write Analytics | Read/Write Cache | Submit Campaigns |
| **Donor** | Read Campaigns | Read Analytics | Read Cache | Submit Donations |
| **Auditor** | Read Only | Read Only | Read Only | Read Only |
| **Supplier** | Read Campaigns | Read Analytics | Read Cache | Read Transactions |

---

## 9. Monitoring & Maintenance

### 9.1 Database Monitoring

#### PostgreSQL Monitoring Queries
```sql
-- Connection monitoring
SELECT 
    state,
    COUNT(*) as connection_count
FROM pg_stat_activity 
WHERE datname = 'kindledger'
GROUP BY state;

-- Query performance monitoring
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;

-- Table size monitoring
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### MongoDB Monitoring
```javascript
// Database statistics
db.stats()

// Collection statistics
db.campaigns_analytics.stats()

// Index usage statistics
db.campaigns_analytics.aggregate([{ $indexStats: {} }])

// Slow query log
db.setProfilingLevel(2, { slowms: 100 })
db.system.profile.find().sort({ ts: -1 }).limit(5)
```

### 9.2 Performance Monitoring Dashboard

#### Key Metrics to Monitor
```yaml
# Prometheus metrics configuration
metrics:
  postgresql:
    - connection_count
    - query_duration
    - transaction_rate
    - lock_wait_time
    - cache_hit_ratio
  
  mongodb:
    - operation_count
    - operation_duration
    - connection_count
    - memory_usage
    - index_usage
  
  redis:
    - memory_usage
    - hit_ratio
    - operation_count
    - connection_count
    - key_expiration_rate
```

### 9.3 Maintenance Tasks

#### Daily Maintenance
```bash
#!/bin/bash
# daily-maintenance.sh

# Update table statistics
docker exec kindledger-postgres psql -U kindledger -d kindledger -c "ANALYZE;"

# Clean up old logs
docker exec kindledger-mongodb mongosh --username kindledger --password kindledger123 --authenticationDatabase kindledger --eval "db.system_logs.deleteMany({timestamp: {\$lt: new Date(Date.now() - 30*24*60*60*1000)}})"

# Redis memory optimization
docker exec kindledger-redis redis-cli -a kindledger123 MEMORY PURGE

# Check disk space
df -h | grep -E "(postgres|mongodb|redis)"

echo "Daily maintenance completed at $(date)"
```

#### Weekly Maintenance
```bash
#!/bin/bash
# weekly-maintenance.sh

# PostgreSQL maintenance
docker exec kindledger-postgres psql -U kindledger -d kindledger -c "VACUUM ANALYZE;"

# MongoDB index optimization
docker exec kindledger-mongodb mongosh --username kindledger --password kindledger123 --authenticationDatabase kindledger --eval "db.campaigns_analytics.reIndex()"

# Redis persistence check
docker exec kindledger-redis redis-cli -a kindledger123 BGSAVE

# Backup verification
./verify-backup.sh

echo "Weekly maintenance completed at $(date)"
```

---

## 10. Production Deployment

### 10.1 Production Configuration

#### High Availability Setup
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  postgres-primary:
    image: postgres:15
    environment:
      POSTGRES_DB: kindledger
      POSTGRES_USER: kindledger
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "5432:5432"
    deploy:
      replicas: 1
      resources:
        limits:
          memory: 4G
          cpus: '2'
        reservations:
          memory: 2G
          cpus: '1'

  postgres-replica:
    image: postgres:15
    environment:
      POSTGRES_DB: kindledger
      POSTGRES_USER: kindledger
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGUSER: kindledger
    command: |
      bash -c "
        until pg_basebackup -h postgres-primary -D /var/lib/postgresql/data -U kindledger -v -P -W; do
          echo 'Waiting for primary to be available...'
          sleep 1
        done
        echo 'Backup done, starting replica...'
        postgres
      "
    depends_on:
      - postgres-primary

  mongodb-primary:
    image: mongo:6
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongodb_data:/data/db
    command: mongod --replSet rs0 --bind_ip_all
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2'

  mongodb-secondary:
    image: mongo:6
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    command: mongod --replSet rs0 --bind_ip_all
    depends_on:
      - mongodb-primary

  redis-cluster:
    image: redis:7-alpine
    command: redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes
    volumes:
      - redis_data:/data
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 1G
          cpus: '0.5'

volumes:
  postgres_data:
  mongodb_data:
  redis_data:
```

### 10.2 Scaling Strategy

#### Horizontal Scaling
```mermaid
graph TB
    subgraph "Load Balancer"
        LB[HAProxy/Nginx]
    end
    
    subgraph "Application Tier"
        APP1[Gateway Instance 1]
        APP2[Gateway Instance 2]
        APP3[Gateway Instance 3]
    end
    
    subgraph "Database Tier"
        PG1[PostgreSQL Primary]
        PG2[PostgreSQL Replica]
        MG1[MongoDB Primary]
        MG2[MongoDB Secondary]
        RD1[Redis Node 1]
        RD2[Redis Node 2]
        RD3[Redis Node 3]
    end
    
    LB --> APP1
    LB --> APP2
    LB --> APP3
    
    APP1 --> PG1
    APP2 --> PG1
    APP3 --> PG1
    
    APP1 --> MG1
    APP2 --> MG1
    APP3 --> MG1
    
    APP1 --> RD1
    APP2 --> RD2
    APP3 --> RD3
```

---

**Last Updated**: 2025-10-28  
**Version**: 1.0  
**Author**: KindLedger Team
