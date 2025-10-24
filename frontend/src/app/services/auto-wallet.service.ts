import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';

export interface WalletInfo {
  walletAddress: string;
  accountNo: string;
  kycStatus: boolean;
  kycLevel: number;
  balance: number;
  createdAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class AutoWalletService {
  private walletInfoSubject = new BehaviorSubject<WalletInfo | null>(null);
  public walletInfo$ = this.walletInfoSubject.asObservable();

  constructor(private http: HttpClient) {}

  /**
   * Tạo ví mới cho người dùng
   * @param accountNo Số tài khoản ngân hàng
   */
  async createWallet(accountNo: string): Promise<WalletInfo> {
    try {
      const response = await this.http.post<any>(`${environment.apiUrl}/api/wallet/create`, {
        accountNo: accountNo
      }).toPromise();

      if (response.walletAddress) {
        const walletInfo: WalletInfo = {
          walletAddress: response.walletAddress,
          accountNo: response.accountNo,
          kycStatus: false,
          kycLevel: 0,
          balance: 0
        };
        
        this.walletInfoSubject.next(walletInfo);
        return walletInfo;
      } else {
        throw new Error('Failed to create wallet');
      }
    } catch (error) {
      console.error('Error creating wallet:', error);
      throw new Error('Failed to create wallet');
    }
  }

  /**
   * Lấy thông tin ví theo số tài khoản
   * @param accountNo Số tài khoản ngân hàng
   */
  async getWalletByAccount(accountNo: string): Promise<WalletInfo | null> {
    try {
      const response = await this.http.get<any>(`${environment.apiUrl}/api/wallet/account/${accountNo}`).toPromise();
      
      if (response.walletAddress) {
        const walletInfo: WalletInfo = {
          walletAddress: response.walletAddress,
          accountNo: response.accountNo,
          kycStatus: response.kycStatus,
          kycLevel: response.kycLevel,
          balance: response.balance
        };
        
        this.walletInfoSubject.next(walletInfo);
        return walletInfo;
      } else {
        return null;
      }
    } catch (error) {
      console.error('Error getting wallet by account:', error);
      return null;
    }
  }

  /**
   * Lấy thông tin ví theo địa chỉ ví
   * @param walletAddress Địa chỉ ví
   */
  async getWalletInfo(walletAddress: string): Promise<WalletInfo | null> {
    try {
      const response = await this.http.get<any>(`${environment.apiUrl}/api/wallet/${walletAddress}`).toPromise();
      
      if (response.walletAddress) {
        const walletInfo: WalletInfo = {
          walletAddress: response.walletAddress,
          accountNo: response.accountNo,
          kycStatus: response.kycStatus,
          kycLevel: response.kycLevel,
          balance: response.balance,
          createdAt: response.createdAt
        };
        
        this.walletInfoSubject.next(walletInfo);
        return walletInfo;
      } else {
        return null;
      }
    } catch (error) {
      console.error('Error getting wallet info:', error);
      return null;
    }
  }

  /**
   * Cập nhật trạng thái KYC
   * @param walletAddress Địa chỉ ví
   * @param kycStatus Trạng thái KYC
   * @param kycLevel Mức độ KYC
   */
  async updateKycStatus(walletAddress: string, kycStatus: boolean, kycLevel: number): Promise<void> {
    try {
      await this.http.put(`${environment.apiUrl}/api/wallet/${walletAddress}/kyc`, {
        kycStatus: kycStatus,
        kycLevel: kycLevel
      }).toPromise();

      // Cập nhật thông tin ví trong state
      const currentWallet = this.walletInfoSubject.value;
      if (currentWallet && currentWallet.walletAddress === walletAddress) {
        currentWallet.kycStatus = kycStatus;
        currentWallet.kycLevel = kycLevel;
        this.walletInfoSubject.next(currentWallet);
      }
    } catch (error) {
      console.error('Error updating KYC status:', error);
      throw new Error('Failed to update KYC status');
    }
  }

  /**
   * Kiểm tra ví có tồn tại không
   * @param walletAddress Địa chỉ ví
   */
  async checkWalletExists(walletAddress: string): Promise<boolean> {
    try {
      const response = await this.http.get<any>(`${environment.apiUrl}/api/wallet/${walletAddress}/exists`).toPromise();
      return response.exists;
    } catch (error) {
      console.error('Error checking wallet existence:', error);
      return false;
    }
  }

  /**
   * Lấy thông tin ví hiện tại
   */
  getCurrentWalletInfo(): WalletInfo | null {
    return this.walletInfoSubject.value;
  }

  /**
   * Kiểm tra ví có được kết nối không
   */
  isWalletConnected(): boolean {
    return this.walletInfoSubject.value !== null;
  }

  /**
   * Lấy địa chỉ ví hiện tại
   */
  getCurrentWalletAddress(): string | null {
    return this.walletInfoSubject.value?.walletAddress || null;
  }

  /**
   * Ngắt kết nối ví
   */
  disconnectWallet(): void {
    this.walletInfoSubject.next(null);
  }

  /**
   * Lấy số dư ví hiện tại
   */
  getCurrentBalance(): number {
    return this.walletInfoSubject.value?.balance || 0;
  }

  /**
   * Kiểm tra trạng thái KYC
   */
  isKycVerified(): boolean {
    return this.walletInfoSubject.value?.kycStatus || false;
  }

  /**
   * Lấy mức độ KYC
   */
  getKycLevel(): number {
    return this.walletInfoSubject.value?.kycLevel || 0;
  }
}
