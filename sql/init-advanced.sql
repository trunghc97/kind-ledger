-- KindLedger Advanced Database Initialization
-- This script includes advanced features like partitioning, indexing, and monitoring

-- Create database if not exists
CREATE DATABASE kindledger;

-- Use the database
\c kindledger;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom types
CREATE TYPE transaction_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED');
CREATE TYPE campaign_status AS ENUM ('ACTIVE', 'COMPLETED', 'CANCELLED', 'SUSPENDED');
CREATE TYPE kyc_level AS ENUM ('NONE', 'BASIC', 'ENHANCED', 'VERIFIED');

-- Create users table with advanced features
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    account_no VARCHAR(20),
    kyc_status BOOLEAN DEFAULT FALSE,
    kyc_level kyc_level DEFAULT 'NONE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create campaigns table with partitioning
CREATE TABLE campaigns (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_amount NUMERIC(18,2) NOT NULL CHECK (target_amount > 0),
    raised_amount NUMERIC(18,2) DEFAULT 0 CHECK (raised_amount >= 0),
    status campaign_status DEFAULT 'ACTIVE',
    deadline TIMESTAMP WITH TIME ZONE,
    evidence_hash VARCHAR(255),
    creator_wallet VARCHAR(42) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
) PARTITION BY RANGE (created_at);

-- Create partitions for campaigns (monthly partitioning)
CREATE TABLE campaigns_2024_01 PARTITION OF campaigns
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE campaigns_2024_02 PARTITION OF campaigns
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE campaigns_2024_03 PARTITION OF campaigns
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
-- Add more partitions as needed

-- Create token_transactions table with partitioning
CREATE TABLE token_transactions (
    id SERIAL,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    tx_hash VARCHAR(66) UNIQUE NOT NULL,
    wallet_address VARCHAR(42) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('MINT', 'BURN', 'DONATE', 'BUY_ITEM', 'REDEEM')),
    amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    campaign_id INTEGER,
    block_number BIGINT,
    gas_used BIGINT,
    gas_price BIGINT,
    status transaction_status DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create partitions for token_transactions (daily partitioning)
CREATE TABLE token_transactions_2024_01_01 PARTITION OF token_transactions
    FOR VALUES FROM ('2024-01-01') TO ('2024-01-02');
CREATE TABLE token_transactions_2024_01_02 PARTITION OF token_transactions
    FOR VALUES FROM ('2024-01-02') TO ('2024-01-03');
-- Add more partitions as needed

-- Create items table
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(18,2) NOT NULL CHECK (price > 0),
    image_url VARCHAR(500),
    campaign_id INTEGER REFERENCES campaigns(id),
    available_quantity INTEGER DEFAULT 0 CHECK (available_quantity >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create item_purchases table
CREATE TABLE item_purchases (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    item_id INTEGER REFERENCES items(id),
    buyer_wallet VARCHAR(42) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    total_amount NUMERIC(18,2) NOT NULL CHECK (total_amount > 0),
    tx_hash VARCHAR(66) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create evidence table
CREATE TABLE evidence (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    campaign_id INTEGER REFERENCES campaigns(id),
    file_hash VARCHAR(255) NOT NULL,
    file_name VARCHAR(255),
    file_size BIGINT,
    mime_type VARCHAR(100),
    ipfs_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create wallet_balances table
CREATE TABLE wallet_balances (
    id SERIAL PRIMARY KEY,
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    c_vnd_balance NUMERIC(18,2) DEFAULT 0 CHECK (c_vnd_balance >= 0),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1
);

-- Create audit_logs table for tracking changes
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(42),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY idx_users_wallet ON users(wallet_address);
CREATE INDEX CONCURRENTLY idx_users_uuid ON users(uuid);
CREATE INDEX CONCURRENTLY idx_users_kyc ON users(kyc_status, kyc_level);

CREATE INDEX CONCURRENTLY idx_campaigns_status ON campaigns(status);
CREATE INDEX CONCURRENTLY idx_campaigns_deadline ON campaigns(deadline);
CREATE INDEX CONCURRENTLY idx_campaigns_creator ON campaigns(creator_wallet);
CREATE INDEX CONCURRENTLY idx_campaigns_created_at ON campaigns(created_at);

CREATE INDEX CONCURRENTLY idx_token_tx_wallet ON token_transactions(wallet_address);
CREATE INDEX CONCURRENTLY idx_token_tx_type ON token_transactions(transaction_type);
CREATE INDEX CONCURRENTLY idx_token_tx_campaign ON token_transactions(campaign_id);
CREATE INDEX CONCURRENTLY idx_token_tx_hash ON token_transactions(tx_hash);
CREATE INDEX CONCURRENTLY idx_token_tx_status ON token_transactions(status);
CREATE INDEX CONCURRENTLY idx_token_tx_created_at ON token_transactions(created_at);

CREATE INDEX CONCURRENTLY idx_items_campaign ON items(campaign_id);
CREATE INDEX CONCURRENTLY idx_items_price ON items(price);

CREATE INDEX CONCURRENTLY idx_item_purchases_buyer ON item_purchases(buyer_wallet);
CREATE INDEX CONCURRENTLY idx_item_purchases_item ON item_purchases(item_id);
CREATE INDEX CONCURRENTLY idx_item_purchases_created_at ON item_purchases(created_at);

CREATE INDEX CONCURRENTLY idx_evidence_campaign ON evidence(campaign_id);
CREATE INDEX CONCURRENTLY idx_evidence_hash ON evidence(file_hash);

CREATE INDEX CONCURRENTLY idx_wallet_balances_address ON wallet_balances(wallet_address);

CREATE INDEX CONCURRENTLY idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX CONCURRENTLY idx_audit_logs_changed_at ON audit_logs(changed_at);

-- Create full-text search indexes
CREATE INDEX CONCURRENTLY idx_campaigns_search ON campaigns USING gin(to_tsvector('english', name || ' ' || description));
CREATE INDEX CONCURRENTLY idx_items_search ON items USING gin(to_tsvector('english', name || ' ' || description));

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_items_updated_at BEFORE UPDATE ON items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to update wallet balance
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_type = 'MINT' THEN
        INSERT INTO wallet_balances (wallet_address, c_vnd_balance)
        VALUES (NEW.wallet_address, NEW.amount)
        ON CONFLICT (wallet_address)
        DO UPDATE SET 
            c_vnd_balance = wallet_balances.c_vnd_balance + NEW.amount,
            last_updated = CURRENT_TIMESTAMP,
            version = wallet_balances.version + 1;
    ELSIF NEW.transaction_type IN ('BURN', 'DONATE', 'BUY_ITEM') THEN
        UPDATE wallet_balances
        SET 
            c_vnd_balance = c_vnd_balance - NEW.amount,
            last_updated = CURRENT_TIMESTAMP,
            version = version + 1
        WHERE wallet_address = NEW.wallet_address;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for balance updates
CREATE TRIGGER trigger_update_wallet_balance
    AFTER INSERT ON token_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_wallet_balance();

-- Create function for audit logging
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, changed_by, changed_at)
        VALUES (TG_TABLE_NAME, OLD.id, TG_OP, row_to_json(OLD), current_user, CURRENT_TIMESTAMP);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_by, changed_at)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(OLD), row_to_json(NEW), current_user, CURRENT_TIMESTAMP);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (table_name, record_id, action, new_values, changed_by, changed_at)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(NEW), current_user, CURRENT_TIMESTAMP);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create audit triggers
CREATE TRIGGER audit_campaigns_trigger
    AFTER INSERT OR UPDATE OR DELETE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_token_transactions_trigger
    AFTER INSERT OR UPDATE OR DELETE ON token_transactions
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Create views for common queries
CREATE VIEW campaign_summary AS
SELECT 
    c.id,
    c.name,
    c.target_amount,
    c.raised_amount,
    c.status,
    c.deadline,
    ROUND((c.raised_amount / c.target_amount * 100), 2) as progress_percentage,
    COUNT(t.id) as transaction_count,
    c.created_at
FROM campaigns c
LEFT JOIN token_transactions t ON c.id = t.campaign_id AND t.transaction_type = 'DONATE'
GROUP BY c.id, c.name, c.target_amount, c.raised_amount, c.status, c.deadline, c.created_at;

CREATE VIEW wallet_summary AS
SELECT 
    wb.wallet_address,
    wb.c_vnd_balance,
    wb.last_updated,
    u.kyc_status,
    u.kyc_level,
    COUNT(tt.id) as transaction_count,
    COALESCE(SUM(CASE WHEN tt.transaction_type = 'MINT' THEN tt.amount ELSE 0 END), 0) as total_minted,
    COALESCE(SUM(CASE WHEN tt.transaction_type = 'BURN' THEN tt.amount ELSE 0 END), 0) as total_burned,
    COALESCE(SUM(CASE WHEN tt.transaction_type = 'DONATE' THEN tt.amount ELSE 0 END), 0) as total_donated
FROM wallet_balances wb
LEFT JOIN users u ON wb.wallet_address = u.wallet_address
LEFT JOIN token_transactions tt ON wb.wallet_address = tt.wallet_address
GROUP BY wb.wallet_address, wb.c_vnd_balance, wb.last_updated, u.kyc_status, u.kyc_level;

-- Insert sample data
INSERT INTO users (wallet_address, account_no, kyc_status, kyc_level) VALUES
('0x627306090abaB3A6e1400e9345bC60c78a8BEf57', '1234567890', true, 'VERIFIED'),
('0xf17f52151EbEF6C7334FAD080c5704D77216b732', '0987654321', true, 'ENHANCED'),
('0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef', '1122334455', false, 'BASIC');

INSERT INTO campaigns (name, description, target_amount, creator_wallet, deadline) VALUES
('Ủng hộ trẻ em nghèo', 'Chiến dịch ủng hộ trẻ em có hoàn cảnh khó khăn', 100000000, '0x627306090abaB3A6e1400e9345bC60c78a8BEf57', '2024-12-31 23:59:59'),
('Xây dựng trường học', 'Xây dựng trường học mới cho trẻ em vùng sâu vùng xa', 500000000, '0xf17f52151EbEF6C7334FAD080c5704D77216b732', '2024-11-30 23:59:59'),
('Hỗ trợ người già neo đơn', 'Chương trình hỗ trợ người già neo đơn trong dịp Tết', 200000000, '0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef', '2024-12-25 23:59:59');

INSERT INTO items (name, description, price, campaign_id, available_quantity) VALUES
('Áo ấm', 'Áo ấm cho trẻ em nghèo', 50000, 1, 100),
('Sách vở', 'Bộ sách vở học tập', 30000, 1, 200),
('Bánh kẹo', 'Bánh kẹo cho trẻ em', 20000, 1, 500),
('Gạch xây dựng', 'Gạch xây dựng trường học', 100000, 2, 1000),
('Xi măng', 'Xi măng xây dựng', 50000, 2, 500),
('Thực phẩm', 'Thực phẩm cho người già', 100000, 3, 100);

INSERT INTO wallet_balances (wallet_address, c_vnd_balance) VALUES
('0x627306090abaB3A6e1400e9345bC60c78a8BEf57', 1000000),
('0xf17f52151EbEF6C7334FAD080c5704D77216b732', 2000000),
('0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef', 1500000);

-- Create monitoring queries
CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_campaigns BIGINT,
    total_transactions BIGINT,
    total_volume NUMERIC,
    active_campaigns BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM campaigns) as total_campaigns,
        (SELECT COUNT(*) FROM token_transactions) as total_transactions,
        (SELECT COALESCE(SUM(amount), 0) FROM token_transactions WHERE status = 'SUCCESS') as total_volume,
        (SELECT COUNT(*) FROM campaigns WHERE status = 'ACTIVE') as active_campaigns;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres;

-- Create database maintenance tasks
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM audit_logs 
    WHERE changed_at < CURRENT_TIMESTAMP - INTERVAL '1 year';
END;
$$ LANGUAGE plpgsql;

-- Create scheduled maintenance (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-audit-logs', '0 2 * * *', 'SELECT cleanup_old_audit_logs();');

COMMENT ON DATABASE kindledger IS 'KindLedger POC Database - Transparent Charity Platform';
COMMENT ON TABLE campaigns IS 'Charity campaigns with transparent tracking';
COMMENT ON TABLE token_transactions IS 'All blockchain transactions with audit trail';
COMMENT ON TABLE wallet_balances IS 'User wallet balances for cVND tokens';
COMMENT ON TABLE audit_logs IS 'Audit trail for all data changes';
