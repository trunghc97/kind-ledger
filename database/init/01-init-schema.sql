-- Kind-Ledger Database Schema
-- PostgreSQL initialization script

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create campaigns table
CREATE TABLE IF NOT EXISTS campaigns (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(500) NOT NULL,
    description TEXT,
    owner VARCHAR(255) NOT NULL,
    goal DECIMAL(15,2) NOT NULL DEFAULT 0,
    raised DECIMAL(15,2) NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata TEXT
);

-- Create donations table
CREATE TABLE IF NOT EXISTS donations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id VARCHAR(255) NOT NULL,
    donor_id VARCHAR(255) NOT NULL,
    donor_name VARCHAR(255) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE
);

-- Create users table (for authentication and user management)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    organization VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'USER',
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) UNIQUE NOT NULL,
    msp_id VARCHAR(255) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL, -- MBBank, Charity, Supplier, Auditor
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Create transactions table (for audit trail)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    campaign_id VARCHAR(255),
    donor_id VARCHAR(255),
    type VARCHAR(50) NOT NULL, -- CREATE_CAMPAIGN, DONATE, QUERY_CAMPAIGN, etc.
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    amount DECIMAL(15,2),
    block_number BIGINT,
    block_hash VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE SET NULL
);

-- Token transactions (for deposit/mint tracking)
CREATE TABLE IF NOT EXISTS token_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tx_ref VARCHAR(120) UNIQUE NOT NULL,
    wallet_address VARCHAR(255) NOT NULL,
    amount DECIMAL(18,6) NOT NULL,
    bank_ref VARCHAR(120),
    token_hash VARCHAR(120) UNIQUE,
    blockchain_tx_id VARCHAR(120),
    block_hash VARCHAR(180),
    status VARCHAR(40) NOT NULL DEFAULT 'SUCCESS',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status);
CREATE INDEX IF NOT EXISTS idx_campaigns_owner ON campaigns(owner);
CREATE INDEX IF NOT EXISTS idx_campaigns_created_at ON campaigns(created_at);
CREATE INDEX IF NOT EXISTS idx_donations_campaign_id ON donations(campaign_id);
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON donations(created_at);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_organization ON users(organization);
CREATE INDEX IF NOT EXISTS idx_transactions_campaign_id ON transactions(campaign_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

-- Create full-text search indexes
CREATE INDEX IF NOT EXISTS idx_campaigns_name_trgm ON campaigns USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_campaigns_description_trgm ON campaigns USING gin (description gin_trgm_ops);

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_donations_updated_at BEFORE UPDATE ON donations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO organizations (name, domain, msp_id, type) VALUES
('MBBank', 'mb.kindledger.com', 'MBBankMSP', 'BANK'),
('Charity Organization', 'charity.kindledger.com', 'CharityMSP', 'CHARITY'),
('Supplier Company', 'supplier.kindledger.com', 'SupplierMSP', 'SUPPLIER'),
('Auditor Agency', 'auditor.kindledger.com', 'AuditorMSP', 'AUDITOR')
ON CONFLICT (domain) DO NOTHING;

-- Insert sample users
INSERT INTO users (username, email, password_hash, full_name, organization, role) VALUES
('admin', 'admin@kindledger.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'System Administrator', 'MBBank', 'ADMIN'),
('charity1', 'charity1@kindledger.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Charity Manager', 'Charity Organization', 'CHARITY_MANAGER'),
('supplier1', 'supplier1@kindledger.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Supplier Manager', 'Supplier Company', 'SUPPLIER_MANAGER'),
('auditor1', 'auditor1@kindledger.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Auditor', 'Auditor Agency', 'AUDITOR')
ON CONFLICT (username) DO NOTHING;

-- Insert sample campaigns
INSERT INTO campaigns (id, name, description, owner, goal, raised, status) VALUES
('campaign-001', 'Hỗ trợ trẻ em nghèo', 'Quyên góp để hỗ trợ trẻ em có hoàn cảnh khó khăn', 'charity1@kindledger.com', 10000000, 0, 'OPEN'),
('campaign-002', 'Xây dựng trường học', 'Xây dựng trường học mới cho vùng sâu vùng xa', 'charity1@kindledger.com', 50000000, 0, 'OPEN'),
('campaign-003', 'Hỗ trợ người già', 'Chăm sóc và hỗ trợ người già neo đơn', 'charity1@kindledger.com', 20000000, 0, 'OPEN')
ON CONFLICT (id) DO NOTHING;

-- Create views for reporting
CREATE OR REPLACE VIEW campaign_stats AS
SELECT 
    c.id,
    c.name,
    c.goal,
    c.raised,
    c.status,
    ROUND((c.raised / c.goal * 100), 2) as progress_percentage,
    COUNT(d.id) as donation_count,
    c.created_at,
    c.updated_at
FROM campaigns c
LEFT JOIN donations d ON c.id = d.campaign_id
GROUP BY c.id, c.name, c.goal, c.raised, c.status, c.created_at, c.updated_at;

CREATE OR REPLACE VIEW donation_summary AS
SELECT 
    DATE(created_at) as donation_date,
    COUNT(*) as total_donations,
    SUM(amount) as total_amount,
    AVG(amount) as average_amount
FROM donations
WHERE status = 'COMPLETED'
GROUP BY DATE(created_at)
ORDER BY donation_date DESC;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kindledger;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO kindledger;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO kindledger;
