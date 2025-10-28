import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Campaign {
  id: string;
  name: string;
  description: string;
  owner: string;
  goal: number;
  raised: number;
  status: string;
  createdAt: string;
  updatedAt: string;
  donors: Donor[];
}

// Payload khi tạo mới campaign: chỉ gửi các trường do client nhập
export interface CreateCampaignRequest {
  name: string;
  description: string;
  owner: string;
  goal: number;
}

export interface Donor {
  id: string;
  name: string;
  amount: number;
  donatedAt: string;
}

export interface DonationRequest {
  campaignId: string;
  donorId: string;
  donorName: string;
  amount: number;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

@Injectable({
  providedIn: 'root'
})
export class CampaignService {
  private apiUrl = '/api';

  constructor(private http: HttpClient) { }

  getAllCampaigns(): Observable<ApiResponse<Campaign[]>> {
    return this.http.get<ApiResponse<Campaign[]>>(`${this.apiUrl}/campaigns`);
  }

  getCampaign(id: string): Observable<ApiResponse<Campaign>> {
    return this.http.get<ApiResponse<Campaign>>(`${this.apiUrl}/campaigns/${id}`);
  }

  createCampaign(payload: CreateCampaignRequest): Observable<ApiResponse<Campaign>> {
    return this.http.post<ApiResponse<Campaign>>(`${this.apiUrl}/campaigns`, payload);
  }

  donate(donation: DonationRequest): Observable<ApiResponse<Campaign>> {
    return this.http.post<ApiResponse<Campaign>>(`${this.apiUrl}/donate`, donation);
  }

  getTotalDonations(): Observable<ApiResponse<number>> {
    return this.http.get<ApiResponse<number>>(`${this.apiUrl}/stats/total`);
  }

  initLedger(): Observable<ApiResponse<any>> {
    return this.http.post<ApiResponse<any>>(`${this.apiUrl}/init`, {});
  }

  getHealth(): Observable<any> {
    return this.http.get(`${this.apiUrl}/health`);
  }
}
