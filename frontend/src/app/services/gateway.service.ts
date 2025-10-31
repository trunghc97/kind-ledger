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
  private apiBase = environment.apiUrl;
  private apiV1 = this.apiBase + '/v1';

  constructor(private http: HttpClient) {}

  // Campaign endpoints
  getCampaigns(): Observable<Campaign[]> {
    return this.http.get<Campaign[]>(`${this.apiV1}/campaigns`);
  }

  getActiveCampaigns(): Observable<Campaign[]> {
    return this.http.get<Campaign[]>(`${this.apiV1}/campaigns/active`);
  }

  getCampaignById(id: number): Observable<Campaign> {
    return this.http.get<Campaign>(`${this.apiV1}/campaigns/${id}`);
  }

  getCampaignProgress(id: number): Observable<number> {
    return this.http.get<number>(`${this.apiV1}/campaigns/${id}/progress`);
  }

  // Transaction endpoints
  donate(data: DonateRequest): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiV1}/donate`, data);
  }

  mint(data: MintRequest): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiV1}/mint`, data);
  }

  burn(walletAddress: string, amount: number): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiV1}/burn`, null, {
      params: { walletAddress, amount: amount.toString() }
    });
  }

  redeem(walletAddress: string, amount: number): Observable<TransactionResponse> {
    return this.http.post<TransactionResponse>(`${this.apiV1}/redeem`, null, {
      params: { walletAddress, amount: amount.toString() }
    });
  }

  deposit(walletAddress: string, amount: number): Observable<any> {
    return this.http.post(`${this.apiV1}/deposit`, { walletAddress, amount });
  }

  // Wallet & user banking
  linkBank(accountNumber: string): Observable<any> {
    return this.http.post(`${this.apiV1}/link-bank`, { accountNumber });
  }

  transfer(fromWalletAddress: string, toWalletAddress: string, amount: number): Observable<any> {
    return this.http.post(`${this.apiV1}/transfer`, { fromWalletAddress, toWalletAddress, amount });
  }

  getWalletBalance(walletAddress: string): Observable<WalletBalance> {
    return this.http.get<WalletBalance>(`${this.apiV1}/wallet/${walletAddress}/balance`);
  }

  getWalletTransactions(walletAddress: string): Observable<Transaction[]> {
    return this.http.get<Transaction[]>(`${this.apiV1}/wallet/${walletAddress}/transactions`);
  }

  checkKyc(walletAddress: string): Observable<string> {
    return this.http.get<string>(`${this.apiV1}/kyc/check`, {
      params: { walletAddress }
    });
  }
}
