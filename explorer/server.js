const express = require('express');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://kindledger:kindledger123@mongodb:27017/kindledger?authSource=admin';

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Fabric configuration
const CHANNEL_NAME = process.env.CHANNEL_NAME || 'kindchannel';
const CHAINCODE_NAME = process.env.CHAINCODE_NAME || 'cvnd-token';
const WALLET_PATH = process.env.WALLET_PATH || '/opt/gopath/src/github.com/hyperledger/fabric/peer/explorer-wallet';
const CONNECTION_PROFILE_PATH = process.env.CONNECTION_PROFILE || '/opt/gopath/src/github.com/hyperledger/fabric/peer/config/connection-profile.yaml';
const MSP_ID = process.env.MSP_ID || 'MBBankMSP';
const ADMIN_LABEL = process.env.ADMIN_IDENTITY || 'Admin@mb.kindledger.com';
const ADMIN_MSP_BASE = process.env.ADMIN_MSP_BASE || '/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mb.kindledger.com/users/Admin@mb.kindledger.com/msp';

let gateway;
let network;
let contract;
let mongo;
let db;

// Initialize Fabric connection
async function initFabric() {
    try {
        console.log('Initializing Fabric connection...');
        
        // Load connection profile
        const connectionProfile = require('yaml').parse(fs.readFileSync(CONNECTION_PROFILE_PATH, 'utf8'));
        
        // Load wallet
        const wallet = await Wallets.newFileSystemWallet(WALLET_PATH);
        
        // Check if user exists
        const label = ADMIN_LABEL;
        let userExists = await wallet.get(label);
        if (!userExists) {
            // Try to import from flat .id file if present
            try {
                const idFile = path.join(WALLET_PATH, `${label}.id`);
                if (fs.existsSync(idFile)) {
                    const raw = fs.readFileSync(idFile, 'utf8');
                    const idJson = JSON.parse(raw);
                    await wallet.put(label, idJson);
                    userExists = await wallet.get(label);
                } else {
                    // Fallback: construct X.509 identity from mounted crypto-config
                    const certPath = path.join(ADMIN_MSP_BASE, 'signcerts');
                    const keyPath = path.join(ADMIN_MSP_BASE, 'keystore');
                    const certFiles = fs.existsSync(certPath) ? fs.readdirSync(certPath).filter(f => f.endsWith('.pem')) : [];
                    const keyFiles = fs.existsSync(keyPath) ? fs.readdirSync(keyPath) : [];
                    if (!certFiles.length || !keyFiles.length) throw new Error('MSP cert/key not found');
                    const certificate = fs.readFileSync(path.join(certPath, certFiles[0]), 'utf8');
                    const privateKey = fs.readFileSync(path.join(keyPath, keyFiles[0]), 'utf8');
                    const identity = { credentials: { certificate, privateKey }, mspId: MSP_ID, type: 'X.509' };
                    await wallet.put(label, identity);
                    userExists = await wallet.get(label);
                }
            } catch (e) {
                console.error('User Admin@mb.kindledger.com not found and import failed:', e.message);
                return;
            }
        }
        
        // Create gateway
        gateway = new Gateway();
        await gateway.connect(connectionProfile, {
            wallet,
            identity: label,
            discovery: { enabled: false, asLocalhost: false }
        });
        
        // Get network and contract
        network = await gateway.getNetwork(CHANNEL_NAME);
        contract = network.getContract(CHAINCODE_NAME);
        
        console.log('Fabric connection initialized successfully');
    } catch (error) {
        console.error('Failed to initialize Fabric connection:', error);
    }
}

// Initialize Mongo connection
async function initMongo() {
    try {
        console.log('Connecting MongoDB...');
        mongo = new MongoClient(MONGODB_URI, { maxPoolSize: 10 });
        await mongo.connect();
        db = mongo.db();
        // Create indexes (idempotent)
        await db.collection('blocks').createIndex({ number: 1 }, { unique: true });
        await db.collection('transactions_ledger').createIndex({ txId: 1 }, { unique: true });
        await db.collection('chaincode_events').createIndex({ txId: 1 });
        console.log('MongoDB connected');
    } catch (err) {
        console.error('MongoDB connection failed:', err.message);
    }
}

// Register block listener to persist ledger events to Mongo
async function registerBlockListener() {
    if (!network || !db) return;
    const channel = network.getChannel();
    await network.addBlockListener(async (blockEvent) => {
        try {
            const blockNumber = parseInt(blockEvent.blockNumber);
            const blockHash = blockEvent.blockData.header.data_hash?.toString('hex');
            const previousHash = blockEvent.blockData.header.previous_hash?.toString('hex');
            const txs = [];
            const events = [];

            for (const txEvent of blockEvent.getTransactionEvents()) {
                const txId = txEvent.transactionId;
                const status = txEvent.status;
                const validationCode = txEvent.validationCode;
                let chaincodeId = null;
                if (txEvent.chaincodeId) chaincodeId = txEvent.chaincodeId;
                txs.push({ txId, status, validationCode, chaincodeId, blockNumber });

                // Chaincode events (if any)
                const ccEvents = txEvent.getContractEvents();
                for (const ev of ccEvents) {
                    events.push({
                        txId,
                        chaincodeId: ev.chaincodeId,
                        eventName: ev.eventName,
                        payload: ev.payload ? ev.payload.toString('utf8') : null,
                        blockNumber,
                    });
                }
            }

            // Upsert block
            await db.collection('blocks').updateOne(
                { number: blockNumber },
                { $set: { number: blockNumber, blockHash, previousHash, transactionCount: txs.length, ts: new Date() } },
                { upsert: true }
            );

            // Insert txs (ignore duplicates)
            if (txs.length) {
                try { await db.collection('transactions_ledger').insertMany(txs, { ordered: false }); } catch (_) {}
            }
            if (events.length) {
                try { await db.collection('chaincode_events').insertMany(events, { ordered: false }); } catch (_) {}
            }
        } catch (err) {
            console.error('Block listener error:', err.message);
        }
    }, { startBlock: 'newest' });
}

// API Routes

// Get all campaigns
app.get('/api/campaigns', async (req, res) => {
    try {
        if (!contract) {
            return res.status(500).json({ error: 'Fabric connection not initialized' });
        }
        
        const result = await contract.evaluateTransaction('QueryAllCampaigns');
        const campaigns = JSON.parse(result.toString());
        
        res.json({
            success: true,
            data: campaigns,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error querying campaigns:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get campaign by ID
app.get('/api/campaigns/:id', async (req, res) => {
    try {
        if (!contract) {
            return res.status(500).json({ error: 'Fabric connection not initialized' });
        }
        
        const { id } = req.params;
        const result = await contract.evaluateTransaction('QueryCampaign', id);
        const campaign = JSON.parse(result.toString());
        
        res.json({
            success: true,
            data: campaign,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error querying campaign:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get total donations
app.get('/api/stats/total', async (req, res) => {
    try {
        if (!contract) {
            return res.status(500).json({ error: 'Fabric connection not initialized' });
        }
        
        const result = await contract.evaluateTransaction('GetTotalDonations');
        const total = parseFloat(result.toString());
        
        res.json({
            success: true,
            data: total,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error getting total donations:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get campaign history
app.get('/api/campaigns/:id/history', async (req, res) => {
    try {
        if (!contract) {
            return res.status(500).json({ error: 'Fabric connection not initialized' });
        }
        
        const { id } = req.params;
        const result = await contract.evaluateTransaction('GetCampaignHistory', id);
        const history = JSON.parse(result.toString());
        
        res.json({
            success: true,
            data: history,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error getting campaign history:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get blockchain info
app.get('/api/blockchain/info', async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: 'Mongo not initialized' });
        const last = await db.collection('blocks').find().sort({ number: -1 }).limit(1).toArray();
        const height = last.length ? last[0].number + 1 : 0;
        res.json({
            success: true,
            data: {
                height: String(height),
                currentBlockHash: last.length ? (last[0].blockHash || '') : '',
                previousBlockHash: last.length ? (last[0].previousHash || '') : '',
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Error getting blockchain info (mongo):', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Get recent blocks
app.get('/api/blocks', async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: 'Mongo not initialized' });
        const limit = Math.min(parseInt(req.query.limit) || 10, 100);
        const blocks = await db.collection('blocks').find().sort({ number: -1 }).limit(limit).toArray();
        res.json({ success: true, data: blocks, timestamp: new Date().toISOString() });
    } catch (error) {
        console.error('Error getting blocks (mongo):', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'UP',
        service: 'Kind-Ledger Explorer',
        timestamp: new Date().toISOString(),
        fabric: gateway ? 'Connected' : 'Disconnected'
    });
});

// Serve static files
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// Start server
async function startServer() {
    await initMongo();
    await initFabric();
    await registerBlockListener();
    
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Kind-Ledger Explorer running on port ${PORT}`);
        console.log(`Health check: http://localhost:${PORT}/api/health`);
    });
}

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('Shutting down gracefully...');
    if (gateway) {
        await gateway.disconnect();
    }
    if (mongo) {
        await mongo.close().catch(() => {});
    }
    process.exit(0);
});

startServer().catch(console.error);
