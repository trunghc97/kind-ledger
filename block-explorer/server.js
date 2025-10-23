const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.EXPLORER_PORT || 8088;

app.use(cors());
app.use(express.json());

// Mock blockchain data
const mockBlocks = [
  {
    number: 1,
    hash: '0xblock1',
    timestamp: Date.now() - 10000,
    transactions: 5,
    size: '1024'
  },
  {
    number: 2,
    hash: '0xblock2',
    timestamp: Date.now() - 5000,
    transactions: 3,
    size: '768'
  },
  {
    number: 3,
    hash: '0xblock3',
    timestamp: Date.now(),
    transactions: 7,
    size: '1536'
  }
];

const mockTransactions = [
  {
    hash: '0xtx1',
    from: '0xmb_bank',
    to: '0xdonor1',
    amount: '1000',
    type: 'mint',
    timestamp: Date.now() - 8000
  },
  {
    hash: '0xtx2',
    from: '0xdonor1',
    to: '0xcharity_campaign',
    amount: '500',
    type: 'donate',
    timestamp: Date.now() - 6000
  },
  {
    hash: '0xtx3',
    from: '0xcharity_campaign',
    to: '0xbeneficiary1',
    amount: '500',
    type: 'disburse',
    timestamp: Date.now() - 4000
  }
];

// Routes
app.get('/api/blocks', (req, res) => {
  res.json({
    blocks: mockBlocks,
    total: mockBlocks.length
  });
});

app.get('/api/transactions', (req, res) => {
  res.json({
    transactions: mockTransactions,
    total: mockTransactions.length
  });
});

app.get('/api/block/:hash', (req, res) => {
  const block = mockBlocks.find(b => b.hash === req.params.hash);
  if (block) {
    res.json(block);
  } else {
    res.status(404).json({ error: 'Block not found' });
  }
});

app.get('/api/transaction/:hash', (req, res) => {
  const tx = mockTransactions.find(t => t.hash === req.params.hash);
  if (tx) {
    res.json(tx);
  } else {
    res.status(404).json({ error: 'Transaction not found' });
  }
});

app.get('/api/stats', (req, res) => {
  res.json({
    totalBlocks: mockBlocks.length,
    totalTransactions: mockTransactions.length,
    totalVolume: '5000 cVND',
    activeAddresses: 15
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'UP',
    service: 'block-explorer',
    port: PORT
  });
});

app.listen(PORT, () => {
  console.log(`Block Explorer running on port ${PORT}`);
});
