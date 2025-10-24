import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { environment } from '../../environments/environment';

declare global {
  interface Window {
    ethereum?: any;
  }
}

@Injectable({
  providedIn: 'root'
})
export class WalletService {
  private walletAddressSubject = new BehaviorSubject<string | null>(null);
  public walletAddress$ = this.walletAddressSubject.asObservable();

  constructor() {}

  async connectWallet(): Promise<string> {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({
          method: 'eth_requestAccounts'
        });
        
        const address = accounts[0];
        this.walletAddressSubject.next(address);
        return address;
      } catch (error) {
        console.error('Error connecting wallet:', error);
        throw new Error('Failed to connect wallet');
      }
    } else {
      throw new Error('MetaMask not installed');
    }
  }

  async getWalletAddress(): Promise<string | null> {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({
          method: 'eth_accounts'
        });
        return accounts[0] || null;
      } catch (error) {
        console.error('Error getting wallet address:', error);
        return null;
      }
    }
    return null;
  }

  async switchNetwork(): Promise<void> {
    if (typeof window.ethereum !== 'undefined') {
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: `0x${environment.blockchain.chainId.toString(16)}` }],
        });
      } catch (error: any) {
        if (error.code === 4902) {
          // Chain doesn't exist, add it
          await this.addNetwork();
        } else {
          throw error;
        }
      }
    }
  }

  private async addNetwork(): Promise<void> {
    if (typeof window.ethereum !== 'undefined') {
      await window.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [{
          chainId: `0x${environment.blockchain.chainId.toString(16)}`,
          chainName: 'KindLedger Network',
          rpcUrls: [environment.blockchain.rpcUrl],
          nativeCurrency: {
            name: 'cVND',
            symbol: 'cVND',
            decimals: 18
          }
        }]
      });
    }
  }

  disconnectWallet(): void {
    this.walletAddressSubject.next(null);
  }

  getCurrentWalletAddress(): string | null {
    return this.walletAddressSubject.value;
  }

  isWalletConnected(): boolean {
    return this.walletAddressSubject.value !== null;
  }
}
