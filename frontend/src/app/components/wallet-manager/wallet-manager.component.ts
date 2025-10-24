import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSnackBarModule, MatSnackBar } from '@angular/material/snack-bar';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AutoWalletService, WalletInfo } from '../../services/auto-wallet.service';

@Component({
  selector: 'app-wallet-manager',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatCardModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatSnackBarModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  template: `
    <div class="wallet-manager">
      <mat-card class="wallet-card">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>account_balance_wallet</mat-icon>
            Quản lý ví KindLedger
          </mat-card-title>
          <mat-card-subtitle>
            Tạo và quản lý ví blockchain tự động
          </mat-card-subtitle>
        </mat-card-header>

        <mat-card-content>
          <!-- Form tạo ví -->
          <div *ngIf="!walletInfo" class="create-wallet-section">
            <form [formGroup]="walletForm" (ngSubmit)="createWallet()">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Số tài khoản ngân hàng</mat-label>
                <input matInput 
                       formControlName="accountNo" 
                       placeholder="Nhập số tài khoản của bạn"
                       maxlength="20">
                <mat-icon matSuffix>account_balance</mat-icon>
                <mat-error *ngIf="walletForm.get('accountNo')?.hasError('required')">
                  Số tài khoản là bắt buộc
                </mat-error>
                <mat-error *ngIf="walletForm.get('accountNo')?.hasError('minlength')">
                  Số tài khoản phải có ít nhất 10 ký tự
                </mat-error>
              </mat-form-field>

              <div class="form-actions">
                <button mat-raised-button 
                        color="primary" 
                        type="submit"
                        [disabled]="walletForm.invalid || isCreating"
                        class="create-button">
                  <mat-spinner *ngIf="isCreating" diameter="20"></mat-spinner>
                  <mat-icon *ngIf="!isCreating">add</mat-icon>
                  {{ isCreating ? 'Đang tạo ví...' : 'Tạo ví mới' }}
                </button>
              </div>
            </form>
          </div>

          <!-- Thông tin ví -->
          <div *ngIf="walletInfo" class="wallet-info-section">
            <div class="wallet-header">
              <h3>
                <mat-icon>check_circle</mat-icon>
                Ví đã được tạo thành công
              </h3>
            </div>

            <div class="wallet-details">
              <div class="detail-item">
                <label>Số tài khoản:</label>
                <span class="account-no">{{ walletInfo.accountNo }}</span>
              </div>

              <div class="detail-item">
                <label>Địa chỉ ví:</label>
                <span class="wallet-address">{{ walletInfo.walletAddress }}</span>
                <button mat-icon-button 
                        (click)="copyToClipboard(walletInfo.walletAddress)"
                        matTooltip="Sao chép địa chỉ ví">
                  <mat-icon>content_copy</mat-icon>
                </button>
              </div>

              <div class="detail-item">
                <label>Số dư:</label>
                <span class="balance">{{ walletInfo.balance | number:'1.2-2' }} cVND</span>
              </div>

              <div class="detail-item">
                <label>Trạng thái KYC:</label>
                <span class="kyc-status" [class.verified]="walletInfo.kycStatus">
                  <mat-icon>{{ walletInfo.kycStatus ? 'check_circle' : 'schedule' }}</mat-icon>
                  {{ walletInfo.kycStatus ? 'Đã xác thực' : 'Chưa xác thực' }}
                </span>
              </div>

              <div class="detail-item" *ngIf="walletInfo.kycStatus">
                <label>Mức độ KYC:</label>
                <span class="kyc-level">Level {{ walletInfo.kycLevel }}</span>
              </div>
            </div>

            <div class="wallet-actions">
              <button mat-raised-button 
                      color="primary"
                      (click)="refreshWalletInfo()"
                      [disabled]="isRefreshing">
                <mat-spinner *ngIf="isRefreshing" diameter="20"></mat-spinner>
                <mat-icon *ngIf="!isRefreshing">refresh</mat-icon>
                {{ isRefreshing ? 'Đang cập nhật...' : 'Cập nhật thông tin' }}
              </button>

              <button mat-stroked-button 
                      color="warn"
                      (click)="disconnectWallet()">
                <mat-icon>logout</mat-icon>
                Ngắt kết nối
              </button>
            </div>
          </div>

          <!-- Hướng dẫn sử dụng -->
          <div class="usage-guide">
            <h4>
              <mat-icon>help_outline</mat-icon>
              Hướng dẫn sử dụng
            </h4>
            <ul>
              <li>Nhập số tài khoản ngân hàng để tạo ví blockchain tự động</li>
              <li>Ví sẽ được liên kết với tài khoản ngân hàng của bạn</li>
              <li>Bạn có thể sử dụng ví để donate và nhận tiền từ các chiến dịch</li>
              <li>Trạng thái KYC sẽ được cập nhật tự động khi bạn xác thực danh tính</li>
            </ul>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .wallet-manager {
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }

    .wallet-card {
      margin-bottom: 20px;
    }

    .create-wallet-section {
      padding: 20px 0;
    }

    .full-width {
      width: 100%;
      margin-bottom: 16px;
    }

    .form-actions {
      text-align: center;
      margin-top: 20px;
    }

    .create-button {
      min-width: 200px;
    }

    .wallet-info-section {
      padding: 20px 0;
    }

    .wallet-header h3 {
      display: flex;
      align-items: center;
      gap: 8px;
      color: #4caf50;
      margin-bottom: 20px;
    }

    .wallet-details {
      background: #f5f5f5;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
    }

    .detail-item {
      display: flex;
      align-items: center;
      margin-bottom: 12px;
      gap: 12px;
    }

    .detail-item label {
      font-weight: 500;
      min-width: 120px;
      color: #666;
    }

    .account-no {
      font-family: monospace;
      font-weight: bold;
      color: #1976d2;
    }

    .wallet-address {
      font-family: monospace;
      font-size: 12px;
      color: #666;
      flex: 1;
      word-break: break-all;
    }

    .balance {
      font-weight: bold;
      color: #4caf50;
      font-size: 16px;
    }

    .kyc-status {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .kyc-status.verified {
      color: #4caf50;
    }

    .kyc-level {
      font-weight: bold;
      color: #ff9800;
    }

    .wallet-actions {
      display: flex;
      gap: 12px;
      justify-content: center;
      margin-top: 20px;
    }

    .usage-guide {
      margin-top: 30px;
      padding: 20px;
      background: #e3f2fd;
      border-radius: 8px;
    }

    .usage-guide h4 {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 12px;
      color: #1976d2;
    }

    .usage-guide ul {
      margin: 0;
      padding-left: 20px;
    }

    .usage-guide li {
      margin-bottom: 8px;
      color: #666;
    }

    mat-spinner {
      margin-right: 8px;
    }
  `]
})
export class WalletManagerComponent implements OnInit {
  walletForm: FormGroup;
  walletInfo: WalletInfo | null = null;
  isCreating = false;
  isRefreshing = false;

  constructor(
    private fb: FormBuilder,
    private walletService: AutoWalletService,
    private snackBar: MatSnackBar
  ) {
    this.walletForm = this.fb.group({
      accountNo: ['', [Validators.required, Validators.minLength(10)]]
    });
  }

  ngOnInit() {
    // Kiểm tra xem đã có ví nào được kết nối chưa
    this.walletService.walletInfo$.subscribe((walletInfo: WalletInfo | null) => {
      this.walletInfo = walletInfo;
    });
  }

  async createWallet() {
    if (this.walletForm.invalid) return;

    this.isCreating = true;
    try {
      const accountNo = this.walletForm.get('accountNo')?.value;
      await this.walletService.createWallet(accountNo);
      
      this.snackBar.open('Ví đã được tạo thành công!', 'Đóng', {
        duration: 3000,
        panelClass: ['success-snackbar']
      });
    } catch (error) {
      this.snackBar.open('Lỗi khi tạo ví: ' + error, 'Đóng', {
        duration: 5000,
        panelClass: ['error-snackbar']
      });
    } finally {
      this.isCreating = false;
    }
  }

  async refreshWalletInfo() {
    if (!this.walletInfo) return;

    this.isRefreshing = true;
    try {
      await this.walletService.getWalletInfo(this.walletInfo.walletAddress);
      this.snackBar.open('Thông tin ví đã được cập nhật!', 'Đóng', {
        duration: 3000,
        panelClass: ['success-snackbar']
      });
    } catch (error) {
      this.snackBar.open('Lỗi khi cập nhật thông tin ví: ' + error, 'Đóng', {
        duration: 5000,
        panelClass: ['error-snackbar']
      });
    } finally {
      this.isRefreshing = false;
    }
  }

  disconnectWallet() {
    this.walletService.disconnectWallet();
    this.walletInfo = null;
    this.snackBar.open('Đã ngắt kết nối ví!', 'Đóng', {
      duration: 3000,
      panelClass: ['info-snackbar']
    });
  }

  copyToClipboard(text: string) {
    navigator.clipboard.writeText(text).then(() => {
      this.snackBar.open('Đã sao chép địa chỉ ví!', 'Đóng', {
        duration: 2000,
        panelClass: ['success-snackbar']
      });
    });
  }
}
