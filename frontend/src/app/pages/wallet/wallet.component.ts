import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTableModule } from '@angular/material/table';
import { MatTabsModule } from '@angular/material/tabs';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { GatewayService } from '../../services/gateway.service';
import { WalletService } from '../../services/wallet.service';
import { WalletBalance, Transaction } from '../../models/transaction.model';

@Component({
  selector: 'app-wallet',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatTableModule,
    MatTabsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSnackBarModule
  ],
  template: `
    <div class="container mx-auto px-4 py-8">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-gray-800 mb-4">Ví của tôi</h1>
        <p class="text-gray-600">Quản lý số dư và giao dịch cVND</p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <!-- Wallet Balance Card -->
        <mat-card class="lg:col-span-1">
          <mat-card-header>
            <mat-card-title class="flex items-center">
              <mat-icon class="mr-2">account_balance_wallet</mat-icon>
              Số dư ví
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="text-center py-4">
              <div class="text-3xl font-bold text-green-600 mb-2">
                {{ walletBalance | currency:'VND':'symbol':'1.0-0':'vi' }}
              </div>
              <p class="text-gray-600">cVND</p>
              <p class="text-sm text-gray-500 mt-2">
                Cập nhật: {{ lastUpdated | date:'dd/MM/yyyy HH:mm' }}
              </p>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Quick Actions -->
        <mat-card class="lg:col-span-2">
          <mat-card-header>
            <mat-card-title>Thao tác nhanh</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <button mat-raised-button color="primary" (click)="showMintForm = !showMintForm">
                <mat-icon>add</mat-icon>
                Nạp tiền
              </button>
              <button mat-raised-button color="warn" (click)="showBurnForm = !showBurnForm">
                <mat-icon>remove</mat-icon>
                Rút tiền
              </button>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Mint Form -->
      <mat-card *ngIf="showMintForm" class="mb-6">
        <mat-card-header>
          <mat-card-title>Nạp tiền vào ví</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <form [formGroup]="mintForm" (ngSubmit)="onMint()" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <mat-form-field appearance="outline">
                <mat-label>Số tài khoản</mat-label>
                <input matInput formControlName="accountNo" placeholder="Nhập số tài khoản">
              </mat-form-field>
              <mat-form-field appearance="outline">
                <mat-label>Số tiền (VND)</mat-label>
                <input matInput type="number" formControlName="amount" placeholder="Nhập số tiền">
              </mat-form-field>
            </div>
            <div class="flex justify-end space-x-2">
              <button mat-button type="button" (click)="showMintForm = false">Hủy</button>
              <button mat-raised-button color="primary" type="submit" [disabled]="!mintForm.valid || isMinting">
                {{ isMinting ? 'Đang xử lý...' : 'Nạp tiền' }}
              </button>
            </div>
          </form>
        </mat-card-content>
      </mat-card>

      <!-- Burn Form -->
      <mat-card *ngIf="showBurnForm" class="mb-6">
        <mat-card-header>
          <mat-card-title>Rút tiền từ ví</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <form [formGroup]="burnForm" (ngSubmit)="onBurn()" class="space-y-4">
            <mat-form-field appearance="outline" class="w-full md:w-1/2">
              <mat-label>Số tiền rút (VND)</mat-label>
              <input matInput type="number" formControlName="amount" placeholder="Nhập số tiền">
            </mat-form-field>
            <div class="flex justify-end space-x-2">
              <button mat-button type="button" (click)="showBurnForm = false">Hủy</button>
              <button mat-raised-button color="warn" type="submit" [disabled]="!burnForm.valid || isBurning">
                {{ isBurning ? 'Đang xử lý...' : 'Rút tiền' }}
              </button>
            </div>
          </form>
        </mat-card-content>
      </mat-card>

      <!-- Transactions Table -->
      <mat-card>
        <mat-card-header>
          <mat-card-title>Lịch sử giao dịch</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="overflow-x-auto">
            <table mat-table [dataSource]="transactions" class="w-full">
              <ng-container matColumnDef="type">
                <th mat-header-cell *matHeaderCellDef>Loại</th>
                <td mat-cell *matCellDef="let transaction">
                  <span [class]="getTransactionTypeClass(transaction.transactionType)">
                    {{ getTransactionTypeLabel(transaction.transactionType) }}
                  </span>
                </td>
              </ng-container>

              <ng-container matColumnDef="amount">
                <th mat-header-cell *matHeaderCellDef>Số tiền</th>
                <td mat-cell *matCellDef="let transaction">
                  <span [class]="getAmountClass(transaction.transactionType)">
                    {{ getAmountPrefix(transaction.transactionType) }}{{ transaction.amount | currency:'VND':'symbol':'1.0-0':'vi' }}
                  </span>
                </td>
              </ng-container>

              <ng-container matColumnDef="status">
                <th mat-header-cell *matHeaderCellDef>Trạng thái</th>
                <td mat-cell *matCellDef="let transaction">
                  <span [class]="getStatusClass(transaction.status)">
                    {{ transaction.status }}
                  </span>
                </td>
              </ng-container>

              <ng-container matColumnDef="createdAt">
                <th mat-header-cell *matHeaderCellDef>Thời gian</th>
                <td mat-cell *matCellDef="let transaction">
                  {{ transaction.createdAt | date:'dd/MM/yyyy HH:mm' }}
                </td>
              </ng-container>

              <ng-container matColumnDef="txHash">
                <th mat-header-cell *matHeaderCellDef>Hash</th>
                <td mat-cell *matCellDef="let transaction">
                  <span class="font-mono text-sm">{{ transaction.txHash | slice:0:10 }}...</span>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
            </table>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .transaction-mint { color: #10b981; }
    .transaction-burn { color: #ef4444; }
    .transaction-donate { color: #3b82f6; }
    .transaction-buy { color: #8b5cf6; }
    .transaction-redeem { color: #f59e0b; }
    
    .status-success { color: #10b981; }
    .status-pending { color: #f59e0b; }
    .status-failed { color: #ef4444; }
  `]
})
export class WalletComponent implements OnInit {
  walletAddress: string | null = null;
  walletBalance: number = 0;
  lastUpdated: string = '';
  transactions: Transaction[] = [];
  displayedColumns: string[] = ['type', 'amount', 'status', 'createdAt', 'txHash'];
  
  showMintForm = false;
  showBurnForm = false;
  isMinting = false;
  isBurning = false;

  mintForm: FormGroup;
  burnForm: FormGroup;

  constructor(
    private gatewayService: GatewayService,
    private walletService: WalletService,
    private snackBar: MatSnackBar,
    private fb: FormBuilder
  ) {
    this.mintForm = this.fb.group({
      accountNo: ['', Validators.required],
      amount: ['', [Validators.required, Validators.min(1000)]]
    });

    this.burnForm = this.fb.group({
      amount: ['', [Validators.required, Validators.min(1000)]]
    });
  }

  ngOnInit() {
    this.walletAddress = this.walletService.getCurrentWalletAddress();
    
    if (!this.walletAddress) {
      this.snackBar.open('Vui lòng kết nối ví trước', 'Đóng', { duration: 3000 });
      return;
    }

    this.loadWalletData();
  }

  loadWalletData() {
    if (this.walletAddress) {
      // Load balance
      this.gatewayService.getWalletBalance(this.walletAddress).subscribe({
        next: (balance) => {
          this.walletBalance = balance.cVndBalance;
          this.lastUpdated = balance.lastUpdated;
        },
        error: (error) => {
          console.error('Error loading wallet balance:', error);
        }
      });

      // Load transactions
      this.gatewayService.getWalletTransactions(this.walletAddress).subscribe({
        next: (transactions) => {
          this.transactions = transactions;
        },
        error: (error) => {
          console.error('Error loading transactions:', error);
        }
      });
    }
  }

  onMint() {
    if (this.mintForm.valid && this.walletAddress) {
      this.isMinting = true;
      const formValue = this.mintForm.value;
      
      this.gatewayService.mint({
        walletAddress: this.walletAddress,
        accountNo: formValue.accountNo,
        amount: formValue.amount
      }).subscribe({
        next: (response) => {
          this.snackBar.open('Nạp tiền thành công!', 'Đóng', { duration: 5000 });
          this.mintForm.reset();
          this.showMintForm = false;
          this.loadWalletData();
        },
        error: (error) => {
          console.error('Error minting:', error);
          this.snackBar.open('Lỗi nạp tiền: ' + error.error?.message, 'Đóng', { duration: 5000 });
        },
        complete: () => {
          this.isMinting = false;
        }
      });
    }
  }

  onBurn() {
    if (this.burnForm.valid && this.walletAddress) {
      this.isBurning = true;
      const formValue = this.burnForm.value;
      
      this.gatewayService.burn(this.walletAddress, formValue.amount).subscribe({
        next: (response) => {
          this.snackBar.open('Rút tiền thành công!', 'Đóng', { duration: 5000 });
          this.burnForm.reset();
          this.showBurnForm = false;
          this.loadWalletData();
        },
        error: (error) => {
          console.error('Error burning:', error);
          this.snackBar.open('Lỗi rút tiền: ' + error.error?.message, 'Đóng', { duration: 5000 });
        },
        complete: () => {
          this.isBurning = false;
        }
      });
    }
  }

  getTransactionTypeLabel(type: string): string {
    const labels: { [key: string]: string } = {
      'MINT': 'Nạp tiền',
      'BURN': 'Rút tiền',
      'DONATE': 'Ủng hộ',
      'BUY_ITEM': 'Mua vật phẩm',
      'REDEEM': 'Đổi token'
    };
    return labels[type] || type;
  }

  getTransactionTypeClass(type: string): string {
    return `transaction-${type.toLowerCase()}`;
  }

  getAmountPrefix(type: string): string {
    return ['MINT', 'DONATE', 'BUY_ITEM'].includes(type) ? '+' : '-';
  }

  getAmountClass(type: string): string {
    return ['MINT', 'DONATE', 'BUY_ITEM'].includes(type) ? 'text-green-600' : 'text-red-600';
  }

  getStatusClass(status: string): string {
    return `status-${status.toLowerCase()}`;
  }
}
