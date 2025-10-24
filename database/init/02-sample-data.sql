-- Kind-Ledger Sample Data
-- Additional sample data for testing

-- Insert more sample campaigns
INSERT INTO campaigns (id, name, description, owner, goal, raised, status, created_at, updated_at, metadata) VALUES
('campaign-004', 'Hỗ trợ bệnh nhân COVID-19', 'Quyên góp để hỗ trợ bệnh nhân COVID-19 và gia đình', 'charity1@kindledger.com', 30000000, 0, 'OPEN', NOW(), NOW(), '{"category": "health", "location": "Vietnam", "targetBeneficiaries": 200}'),
('campaign-005', 'Xây dựng cầu nông thôn', 'Xây dựng cầu nông thôn để kết nối các vùng xa xôi', 'charity1@kindledger.com', 80000000, 0, 'OPEN', NOW(), NOW(), '{"category": "infrastructure", "location": "Rural areas", "targetBeneficiaries": 1000}'),
('campaign-006', 'Hỗ trợ giáo dục trẻ em', 'Cung cấp sách vở và dụng cụ học tập cho trẻ em nghèo', 'charity1@kindledger.com', 15000000, 0, 'OPEN', NOW(), NOW(), '{"category": "education", "location": "Mountain areas", "targetBeneficiaries": 300}'),
('campaign-007', 'Bảo vệ môi trường', 'Trồng cây và bảo vệ môi trường sống', 'charity1@kindledger.com', 25000000, 0, 'OPEN', NOW(), NOW(), '{"category": "environment", "location": "National parks", "targetBeneficiaries": 500}'),
('campaign-008', 'Hỗ trợ người khuyết tật', 'Cung cấp thiết bị hỗ trợ cho người khuyết tật', 'charity1@kindledger.com', 40000000, 0, 'OPEN', NOW(), NOW(), '{"category": "disability", "location": "Urban areas", "targetBeneficiaries": 150}')
ON CONFLICT (id) DO NOTHING;

-- Insert sample donations
INSERT INTO donations (id, campaign_id, donor_id, donor_name, amount, transaction_id, status, created_at, updated_at, metadata) VALUES
(gen_random_uuid(), 'campaign-001', 'donor-001', 'Nguyễn Văn A', 500000, 'tx-001', 'COMPLETED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', '{"payment_method": "bank_transfer", "anonymous": false}'),
(gen_random_uuid(), 'campaign-001', 'donor-002', 'Trần Thị B', 1000000, 'tx-002', 'COMPLETED', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"payment_method": "credit_card", "anonymous": false}'),
(gen_random_uuid(), 'campaign-002', 'donor-003', 'Lê Văn C', 2000000, 'tx-003', 'COMPLETED', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours', '{"payment_method": "bank_transfer", "anonymous": false}'),
(gen_random_uuid(), 'campaign-002', 'donor-004', 'Phạm Thị D', 1500000, 'tx-004', 'COMPLETED', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour', '{"payment_method": "mobile_payment", "anonymous": false}'),
(gen_random_uuid(), 'campaign-003', 'donor-005', 'Anonymous', 300000, 'tx-005', 'COMPLETED', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes', '{"payment_method": "bank_transfer", "anonymous": true}'),
(gen_random_uuid(), 'campaign-004', 'donor-006', 'Hoàng Văn E', 800000, 'tx-006', 'COMPLETED', NOW() - INTERVAL '15 minutes', NOW() - INTERVAL '15 minutes', '{"payment_method": "credit_card", "anonymous": false}'),
(gen_random_uuid(), 'campaign-005', 'donor-007', 'Vũ Thị F', 1200000, 'tx-007', 'PENDING', NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '5 minutes', '{"payment_method": "bank_transfer", "anonymous": false}'),
(gen_random_uuid(), 'campaign-006', 'donor-008', 'Đặng Văn G', 600000, 'tx-008', 'COMPLETED', NOW() - INTERVAL '2 minutes', NOW() - INTERVAL '2 minutes', '{"payment_method": "mobile_payment", "anonymous": false}')
ON CONFLICT (id) DO NOTHING;

-- Insert sample transactions
INSERT INTO transactions (id, transaction_id, campaign_id, donor_id, type, status, amount, block_number, block_hash, created_at, metadata) VALUES
(gen_random_uuid(), 'tx-001', 'campaign-001', 'donor-001', 'DONATE', 'COMPLETED', 500000, 1001, '0xabc123...', NOW() - INTERVAL '2 days', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'tx-002', 'campaign-001', 'donor-002', 'DONATE', 'COMPLETED', 1000000, 1002, '0xdef456...', NOW() - INTERVAL '1 day', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'tx-003', 'campaign-002', 'donor-003', 'DONATE', 'COMPLETED', 2000000, 1003, '0xghi789...', NOW() - INTERVAL '3 hours', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'tx-004', 'campaign-002', 'donor-004', 'DONATE', 'COMPLETED', 1500000, 1004, '0xjkl012...', NOW() - INTERVAL '1 hour', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'tx-005', 'campaign-003', 'donor-005', 'DONATE', 'COMPLETED', 300000, 1005, '0xmno345...', NOW() - INTERVAL '30 minutes', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'tx-006', 'campaign-004', 'donor-006', 'DONATE', 'COMPLETED', 800000, 1006, '0xpqr678...', NOW() - INTERVAL '15 minutes', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'tx-007', 'campaign-005', 'donor-007', 'DONATE', 'PENDING', 1200000, NULL, NULL, NOW() - INTERVAL '5 minutes', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'tx-008', 'campaign-006', 'donor-008', 'DONATE', 'COMPLETED', 600000, 1007, '0xstu901...', NOW() - INTERVAL '2 minutes', '{"gas_used": 21000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'create-campaign-001', 'campaign-001', 'charity1@kindledger.com', 'CREATE_CAMPAIGN', 'COMPLETED', 0, 1000, '0xcreate001...', NOW() - INTERVAL '5 days', '{"gas_used": 50000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'create-campaign-002', 'campaign-002', 'charity1@kindledger.com', 'CREATE_CAMPAIGN', 'COMPLETED', 0, 1000, '0xcreate002...', NOW() - INTERVAL '4 days', '{"gas_used": 50000, "gas_price": "20000000000"}'),
(gen_random_uuid(), 'create-campaign-003', 'campaign-003', 'charity1@kindledger.com', 'CREATE_CAMPAIGN', 'COMPLETED', 0, 1000, '0xcreate003...', NOW() - INTERVAL '3 days', '{"gas_used": 50000, "gas_price": "20000000000"}')
ON CONFLICT (id) DO NOTHING;

-- Update campaign raised amounts based on completed donations
UPDATE campaigns 
SET raised = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM donations 
    WHERE campaign_id = campaigns.id 
    AND status = 'COMPLETED'
),
updated_at = NOW()
WHERE id IN ('campaign-001', 'campaign-002', 'campaign-003', 'campaign-004', 'campaign-005', 'campaign-006');

-- Update campaign status to COMPLETED if goal is reached
UPDATE campaigns 
SET status = 'COMPLETED', 
    completed_at = NOW(),
    updated_at = NOW()
WHERE raised >= goal 
AND status = 'OPEN';

-- Create some additional users
INSERT INTO users (id, username, email, password_hash, full_name, organization, role, status, created_at, updated_at, metadata) VALUES
(gen_random_uuid(), 'charity2', 'charity2@kindledger.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Charity Manager 2', 'Charity Organization', 'CHARITY_MANAGER', 'ACTIVE', NOW(), NOW(), '{}'),
(gen_random_uuid(), 'supplier2', 'supplier2@kindledger.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Supplier Manager 2', 'Supplier Company', 'SUPPLIER_MANAGER', 'ACTIVE', NOW(), NOW(), '{}'),
(gen_random_uuid(), 'auditor2', 'auditor2@kindledger.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Auditor 2', 'Auditor Agency', 'AUDITOR', 'ACTIVE', NOW(), NOW(), '{}'),
(gen_random_uuid(), 'donor1', 'donor1@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Donor 1', 'Individual', 'USER', 'ACTIVE', NOW(), NOW(), '{}'),
(gen_random_uuid(), 'donor2', 'donor2@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Donor 2', 'Individual', 'USER', 'ACTIVE', NOW(), NOW(), '{}')
ON CONFLICT (username) DO NOTHING;

-- Create some additional organizations
INSERT INTO organizations (id, name, domain, msp_id, type, status, created_at, updated_at, metadata) VALUES
(gen_random_uuid(), 'Additional Charity', 'charity2.kindledger.com', 'Charity2MSP', 'CHARITY', 'ACTIVE', NOW(), NOW(), '{}'),
(gen_random_uuid(), 'Additional Supplier', 'supplier2.kindledger.com', 'Supplier2MSP', 'SUPPLIER', 'ACTIVE', NOW(), NOW(), '{}'),
(gen_random_uuid(), 'Additional Auditor', 'auditor2.kindledger.com', 'Auditor2MSP', 'AUDITOR', 'ACTIVE', NOW(), NOW(), '{}')
ON CONFLICT (domain) DO NOTHING;

-- Create indexes for better performance on the new data
CREATE INDEX IF NOT EXISTS idx_donations_campaign_status ON donations(campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_donations_donor_status ON donations(donor_id, status);
CREATE INDEX IF NOT EXISTS idx_transactions_campaign_type ON transactions(campaign_id, type);
CREATE INDEX IF NOT EXISTS idx_transactions_donor_type ON transactions(donor_id, type);
CREATE INDEX IF NOT EXISTS idx_transactions_status_type ON transactions(status, type);

-- Create a view for campaign progress
CREATE OR REPLACE VIEW campaign_progress AS
SELECT 
    c.id,
    c.name,
    c.goal,
    c.raised,
    c.status,
    ROUND((c.raised / c.goal * 100), 2) as progress_percentage,
    COUNT(d.id) as donation_count,
    COALESCE(AVG(d.amount), 0) as average_donation,
    c.created_at,
    c.updated_at,
    CASE 
        WHEN c.raised >= c.goal THEN 'COMPLETED'
        WHEN c.raised >= c.goal * 0.8 THEN 'NEARLY_COMPLETED'
        WHEN c.raised >= c.goal * 0.5 THEN 'HALF_COMPLETED'
        WHEN c.raised >= c.goal * 0.2 THEN 'STARTED'
        ELSE 'JUST_STARTED'
    END as progress_status
FROM campaigns c
LEFT JOIN donations d ON c.id = d.campaign_id AND d.status = 'COMPLETED'
GROUP BY c.id, c.name, c.goal, c.raised, c.status, c.created_at, c.updated_at;

-- Create a view for donor statistics
CREATE OR REPLACE VIEW donor_statistics AS
SELECT 
    d.donor_id,
    d.donor_name,
    COUNT(d.id) as total_donations,
    SUM(d.amount) as total_amount,
    AVG(d.amount) as average_donation,
    MIN(d.created_at) as first_donation,
    MAX(d.created_at) as last_donation,
    COUNT(DISTINCT d.campaign_id) as campaigns_supported
FROM donations d
WHERE d.status = 'COMPLETED'
GROUP BY d.donor_id, d.donor_name;

print('Sample data inserted successfully!');
