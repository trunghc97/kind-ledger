const express = require('express');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Fabric configuration
const CHANNEL_NAME = 'kindchannel';
const CHAINCODE_NAME = 'kindledgercc';
const WALLET_PATH = path.join(__dirname, 'wallet');
const CONNECTION_PROFILE_PATH = path.join(__dirname, '..', 'blockchain', 'config', 'connection-profile.yaml');

let gateway;
let network;
let contract;

// Initialize Fabric connection
async function initFabric() {
    try {
        console.log('Initializing Fabric connection...');
        
        // Load connection profile
        const connectionProfile = require('yaml').parse(fs.readFileSync(CONNECTION_PROFILE_PATH, 'utf8'));
        
        // Load wallet
        const wallet = await Wallets.newFileSystemWallet(WALLET_PATH);
        
        // Check if user exists
        const userExists = await wallet.exists('Admin@mb.kindledger.com');
        if (!userExists) {
            console.error('User Admin@mb.kindledger.com not found in wallet');
            return;
        }
        
        // Create gateway
        gateway = new Gateway();
        await gateway.connect(connectionProfile, {
            wallet,
            identity: 'Admin@mb.kindledger.com',
            discovery: { enabled: true, asLocalhost: true }
        });
        
        // Get network and contract
        network = await gateway.getNetwork(CHANNEL_NAME);
        contract = network.getContract(CHAINCODE_NAME);
        
        console.log('Fabric connection initialized successfully');
    } catch (error) {
        console.error('Failed to initialize Fabric connection:', error);
    }
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
        if (!network) {
            return res.status(500).json({ error: 'Fabric connection not initialized' });
        }
        
        const channel = network.getChannel();
        const info = await channel.queryInfo();
        
        res.json({
            success: true,
            data: {
                height: info.height.toString(),
                currentBlockHash: info.currentBlockHash.toString('hex'),
                previousBlockHash: info.previousBlockHash.toString('hex'),
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Error getting blockchain info:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get recent blocks
app.get('/api/blocks', async (req, res) => {
    try {
        if (!network) {
            return res.status(500).json({ error: 'Fabric connection not initialized' });
        }
        
        const channel = network.getChannel();
        const info = await channel.queryInfo();
        const height = parseInt(info.height.toString());
        
        const blocks = [];
        const startBlock = Math.max(0, height - 10); // Get last 10 blocks
        
        for (let i = startBlock; i < height; i++) {
            try {
                const block = await channel.queryBlock(i);
                blocks.push({
                    blockNumber: i,
                    blockHash: block.header.data_hash.toString('hex'),
                    previousHash: block.header.previous_hash.toString('hex'),
                    transactionCount: block.data.data.length,
                    timestamp: new Date().toISOString()
                });
            } catch (err) {
                console.warn(`Could not fetch block ${i}:`, err.message);
            }
        }
        
        res.json({
            success: true,
            data: blocks.reverse(), // Most recent first
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error getting blocks:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
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
    await initFabric();
    
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
    process.exit(0);
});

startServer().catch(console.error);