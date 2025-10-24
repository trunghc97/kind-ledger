-- KindLedger Database Schema
-- PostgreSQL initialization script

-- Create database if not exists
CREATE DATABASE kindledger;

-- Use the database
\c kindledger;

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    account_no VARCHAR(20),
    kyc_status BOOLEAN DEFAULT FALSE,
    kyc_level INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create campaigns table
CREATE TABLE campaigns (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_amount NUMERIC(18,2) NOT NULL,
    raised_amount NUMERIC(18,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    deadline TIMESTAMP,
    evidence_hash VARCHAR(255),
    creator_wallet VARCHAR(42) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create token_transactions table
CREATE TABLE token_transactions (
    id SERIAL PRIMARY KEY,
    tx_hash VARCHAR(66) UNIQUE NOT NULL,
    wallet_address VARCHAR(42) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- MINT, BURN, DONATE, BUY_ITEM, REDEEM
    amount NUMERIC(18,2) NOT NULL,
    campaign_id INTEGER REFERENCES campaigns(id),
    block_number BIGINT,
    gas_used BIGINT,
    gas_price BIGINT,
    status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create items table for charity items
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(18,2) NOT NULL,
    image_url VARCHAR(500),
    campaign_id INTEGER REFERENCES campaigns(id),
    available_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create item_purchases table
CREATE TABLE item_purchases (
    id SERIAL PRIMARY KEY,
    item_id INTEGER REFERENCES items(id),
    buyer_wallet VARCHAR(42) NOT NULL,
    quantity INTEGER NOT NULL,
    total_amount NUMERIC(18,2) NOT NULL,
    tx_hash VARCHAR(66) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create evidence table for IPFS storage
CREATE TABLE evidence (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER REFERENCES campaigns(id),
    file_hash VARCHAR(255) NOT NULL,
    file_name VARCHAR(255),
    file_size BIGINT,
    mime_type VARCHAR(100),
    ipfs_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create wallet_balances table
CREATE TABLE wallet_balances (
    id SERIAL PRIMARY KEY,
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    c_vnd_balance NUMERIC(18,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_wallet ON users(wallet_address);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_deadline ON campaigns(deadline);
CREATE INDEX idx_token_tx_wallet ON token_transactions(wallet_address);
CREATE INDEX idx_token_tx_type ON token_transactions(transaction_type);
CREATE INDEX idx_token_tx_campaign ON token_transactions(campaign_id);
CREATE INDEX idx_token_tx_hash ON token_transactions(tx_hash);
CREATE INDEX idx_items_campaign ON items(campaign_id);
CREATE INDEX idx_item_purchases_buyer ON item_purchases(buyer_wallet);
CREATE INDEX idx_evidence_campaign ON evidence(campaign_id);
CREATE INDEX idx_wallet_balances_address ON wallet_balances(wallet_address);

-- Insert sample data
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

-- Insert sample wallet balances
INSERT INTO wallet_balances (wallet_address, c_vnd_balance) VALUES
('0x627306090abaB3A6e1400e9345bC60c78a8BEf57', 1000000),
('0xf17f52151EbEF6C7334FAD080c5704D77216b732', 2000000),
('0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef', 1500000);

-- Create function to update wallet balance
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_type = 'MINT' THEN
        INSERT INTO wallet_balances (wallet_address, c_vnd_balance)
        VALUES (NEW.wallet_address, NEW.amount)
        ON CONFLICT (wallet_address)
        DO UPDATE SET c_vnd_balance = wallet_balances.c_vnd_balance + NEW.amount,
                      last_updated = CURRENT_TIMESTAMP;
    ELSIF NEW.transaction_type = 'BURN' OR NEW.transaction_type = 'DONATE' OR NEW.transaction_type = 'BUY_ITEM' THEN
        UPDATE wallet_balances
        SET c_vnd_balance = c_vnd_balance - NEW.amount,
            last_updated = CURRENT_TIMESTAMP
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
