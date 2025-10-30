import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Campaign, CampaignProgress } from '../models/campaign.model';
import { Transaction, WalletBalance, DonateRequest, MintRequest, TransactionResponse } from '../models/transaction.model';

@Injectable({
  providedIn: 'root'
})
export class GatewayService {
  private apiBase = environment.apiBase;

  constructor(private http: HttpClient) {}

  // Campaign endpoints
  getCampaigns(): Observable<Campaign[]> {
    return this.http.get<Campaign[]>(`${this.apiBase}/campaigns`);
  }

  getActiveCampaigns(): Observable<Campaign[]> {
    return this.http.get<Campaign[]>(`${this.apiBase}/campaigns/active`);
  }

  getCampaignById(id: number): Observable<Campaign> {
    return this.http.get<Campaign>(`${this.apiBase}/campaigns/${id}`);
  }

  getCampaignProgress(id: number): Observable<number> {
    return this.http.get<number>(`${this.apiBase}/campaigns/${id}/progress`);
  }

  // Transaction endpoints
  donate(data: DonateRequest): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiBase}/donate`, data);
  }

  mint(data: MintRequest): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiBase}/mint`, data);
  }

  burn(walletAddress: string, amount: number): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiBase}/burn`, null, {
      params: { walletAddress, amount: amount.toString() }
    });
  }

  redeem(walletAddress: string, amount: number): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiBase}/redeem`, null, {
      params: { walletAddress, amount: amount.toString() }
    });
  }

  // Wallet & user banking
  linkBank(userId: string, accountNumber: string): Observable<any> {
    return this.http.post(`${this.apiBase}/users/${userId}/link-bank`, { accountNumber });
  }

  transfer(fromWalletAddress: string, toWalletAddress: string, amount: number): Observable<any> {
    return this.http.post(`${this.apiBase}/transfer`, { fromWalletAddress, toWalletAddress, amount });
  }

  getWalletBalance(walletAddress: string): Observable<WalletBalance> {
    return this.http.get<WalletBalance>(`${this.apiBase}/wallet/${walletAddress}/balance`);
  }

  getWalletTransactions(walletAddress: string): Observable<Transaction[]> {
    return this.http.get<Transaction[]>(`${this.apiBase}/wallet/${walletAddress}/transactions`);
  }

  checkKyc(walletAddress: string): Observable<string> {
    return this.http.get<string>(`${this.apiBase}/kyc/check`, {
      params: { walletAddress }
    });
  }
}
