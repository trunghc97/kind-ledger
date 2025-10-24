const express = require('express');
const Web3 = require('web3');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

const app = express();
const PORT = process.env.PORT || 8088;

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json());

// Web3 connection
const web3 = new Web3(process.env.BESU_URL || 'http://besu-validator:8545');

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/api/network', async (req, res) => {
  try {
    const chainId = await web3.eth.getChainId();
    const blockNumber = await web3.eth.getBlockNumber();
    const gasPrice = await web3.eth.getGasPrice();
    
    res.json({
      chainId: chainId.toString(),
      blockNumber: blockNumber.toString(),
      gasPrice: gasPrice.toString(),
      networkName: 'KindLedger Network'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/blocks/:blockNumber', async (req, res) => {
  try {
    const blockNumber = req.params.blockNumber;
    const block = await web3.eth.getBlock(blockNumber, true);
    res.json(block);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/transactions/:txHash', async (req, res) => {
  try {
    const txHash = req.params.txHash;
    const transaction = await web3.eth.getTransaction(txHash);
    const receipt = await web3.eth.getTransactionReceipt(txHash);
    
    res.json({
      transaction,
      receipt
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/accounts/:address', async (req, res) => {
  try {
    const address = req.params.address;
    const balance = await web3.eth.getBalance(address);
    const transactionCount = await web3.eth.getTransactionCount(address);
    
    res.json({
      address,
      balance: balance.toString(),
      transactionCount: transactionCount.toString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/blocks', async (req, res) => {
  try {
    const latestBlock = await web3.eth.getBlockNumber();
    const limit = parseInt(req.query.limit) || 10;
    const blocks = [];
    
    for (let i = 0; i < limit; i++) {
      const blockNumber = latestBlock - i;
      if (blockNumber < 0) break;
      
      const block = await web3.eth.getBlock(blockNumber);
      blocks.push({
        number: block.number,
        hash: block.hash,
        parentHash: block.parentHash,
        timestamp: block.timestamp,
        gasUsed: block.gasUsed,
        gasLimit: block.gasLimit,
        transactionCount: block.transactions.length
      });
    }
    
    res.json(blocks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Serve static files
app.use(express.static('public'));

// Serve the main explorer page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>KindLedger Explorer</title>
        <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gray-100">
        <div class="container mx-auto px-4 py-8">
            <h1 class="text-3xl font-bold text-center mb-8">KindLedger Blockchain Explorer</h1>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div class="bg-white p-6 rounded-lg shadow">
                    <h3 class="text-lg font-semibold mb-2">Network Info</h3>
                    <div id="network-info">Loading...</div>
                </div>
                
                <div class="bg-white p-6 rounded-lg shadow">
                    <h3 class="text-lg font-semibold mb-2">Latest Blocks</h3>
                    <div id="latest-blocks">Loading...</div>
                </div>
                
                <div class="bg-white p-6 rounded-lg shadow">
                    <h3 class="text-lg font-semibold mb-2">Search</h3>
                    <input type="text" id="search-input" placeholder="Enter address or hash" 
                           class="w-full p-2 border rounded mb-2">
                    <button onclick="search()" class="bg-blue-500 text-white px-4 py-2 rounded">Search</button>
                </div>
            </div>
            
            <div class="bg-white p-6 rounded-lg shadow">
                <h3 class="text-lg font-semibold mb-4">Recent Blocks</h3>
                <div id="blocks-table">Loading...</div>
            </div>
        </div>
        
        <script>
            async function loadNetworkInfo() {
                try {
                    const response = await fetch('/api/network');
                    const data = await response.json();
                    document.getElementById('network-info').innerHTML = \`
                        <p><strong>Chain ID:</strong> \${data.chainId}</p>
                        <p><strong>Block:</strong> \${data.blockNumber}</p>
                        <p><strong>Gas Price:</strong> \${data.gasPrice}</p>
                    \`;
                } catch (error) {
                    document.getElementById('network-info').innerHTML = 'Error loading network info';
                }
            }
            
            async function loadBlocks() {
                try {
                    const response = await fetch('/api/blocks?limit=5');
                    const blocks = await response.json();
                    let html = '<div class="space-y-2">';
                    blocks.forEach(block => {
                        html += \`
                            <div class="p-3 border rounded">
                                <p><strong>Block #\${block.number}</strong></p>
                                <p class="text-sm text-gray-600">Hash: \${block.hash}</p>
                                <p class="text-sm text-gray-600">Transactions: \${block.transactionCount}</p>
                            </div>
                        \`;
                    });
                    html += '</div>';
                    document.getElementById('blocks-table').innerHTML = html;
                } catch (error) {
                    document.getElementById('blocks-table').innerHTML = 'Error loading blocks';
                }
            }
            
            function search() {
                const input = document.getElementById('search-input').value;
                if (input) {
                    window.open(\`/search.html?q=\${input}\`, '_blank');
                }
            }
            
            // Load data on page load
            loadNetworkInfo();
            loadBlocks();
        </script>
    </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`KindLedger Explorer running on port ${PORT}`);
});
