import { useState } from 'react';
import Head from 'next/head';

export default function Home() {
  const [walletAddress, setWalletAddress] = useState('');
  const [balance, setBalance] = useState('0');

  const connectWallet = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({
          method: 'eth_requestAccounts',
        });
        setWalletAddress(accounts[0]);
      } catch (error) {
        console.error('Error connecting wallet:', error);
      }
    } else {
      alert('Please install MetaMask!');
    }
  };

  const getBalance = async () => {
    if (walletAddress) {
      try {
        const response = await fetch(`http://localhost:8080/api/balance/${walletAddress}`);
        const data = await response.json();
        setBalance(data.balance || '0');
      } catch (error) {
        console.error('Error fetching balance:', error);
      }
    }
  };

  return (
    <div className="container">
      <Head>
        <title>KindLedger - Hệ thống chuyển tiền thiện nguyện</title>
        <meta name="description" content="Hệ thống chuyển tiền thiện nguyện token hóa" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="main">
        <h1 className="title">
          KindLedger
        </h1>
        
        <p className="description">
          Hệ thống chuyển tiền thiện nguyện token hóa (Bank‑as‑Node)
        </p>

        <div className="wallet-section">
          <h2>Ví cVND</h2>
          {!walletAddress ? (
            <button onClick={connectWallet} className="connect-button">
              Kết nối ví MetaMask
            </button>
          ) : (
            <div className="wallet-info">
              <p><strong>Địa chỉ ví:</strong> {walletAddress}</p>
              <p><strong>Số dư cVND:</strong> {balance}</p>
              <button onClick={getBalance} className="balance-button">
                Làm mới số dư
              </button>
            </div>
          )}
        </div>

        <div className="features">
          <h2>Tính năng chính</h2>
          <ul>
            <li>Minh bạch tuyệt đối hành trình tiền từ thiện</li>
            <li>Token hóa VND thành cVND (1:1)</li>
            <li>Giao dịch on-chain với blockchain</li>
            <li>Nạp/rút tiền qua ngân hàng</li>
            <li>Giám sát real-time bởi chính phủ</li>
          </ul>
        </div>
      </main>

      <style jsx>{`
        .container {
          min-height: 100vh;
          padding: 0 0.5rem;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
        }

        .main {
          padding: 5rem 0;
          flex: 1;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          max-width: 800px;
          width: 100%;
        }

        .title {
          margin: 0;
          line-height: 1.15;
          font-size: 4rem;
          text-align: center;
          color: #0070f3;
        }

        .description {
          margin: 2rem 0;
          line-height: 1.5;
          font-size: 1.5rem;
          text-align: center;
          color: #666;
        }

        .wallet-section {
          margin: 2rem 0;
          padding: 2rem;
          border: 1px solid #eaeaea;
          border-radius: 10px;
          width: 100%;
          max-width: 500px;
        }

        .connect-button, .balance-button {
          background-color: #0070f3;
          color: white;
          border: none;
          padding: 1rem 2rem;
          border-radius: 5px;
          cursor: pointer;
          font-size: 1rem;
        }

        .connect-button:hover, .balance-button:hover {
          background-color: #0051a2;
        }

        .wallet-info {
          text-align: left;
        }

        .features {
          margin: 2rem 0;
          text-align: left;
          width: 100%;
          max-width: 600px;
        }

        .features ul {
          list-style-type: disc;
          padding-left: 2rem;
        }

        .features li {
          margin: 0.5rem 0;
          line-height: 1.5;
        }
      `}</style>
    </div>
  );
}
