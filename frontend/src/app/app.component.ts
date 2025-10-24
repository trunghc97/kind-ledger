import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterModule } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { AutoWalletService, WalletInfo } from './services/auto-wallet.service';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    RouterModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatMenuModule
  ],
  template: `
    <mat-toolbar color="primary" class="flex justify-between items-center">
      <div class="flex items-center">
        <mat-icon class="mr-2">favorite</mat-icon>
        <span class="text-xl font-bold">KindLedger</span>
      </div>
      
      <div class="flex items-center space-x-4">
        <button mat-button routerLink="/campaigns">Chiến dịch</button>
        <button mat-button routerLink="/donate">Ủng hộ</button>
        <button mat-button routerLink="/buy-item">Mua vật phẩm</button>
        
        <div *ngIf="walletInfo$ | async as walletInfo; else connectButton">
          <button mat-button [matMenuTriggerFor]="walletMenu" class="wallet-connected">
            <mat-icon>account_balance_wallet</mat-icon>
            {{ walletInfo.accountNo }}
          </button>
          <mat-menu #walletMenu="matMenu">
            <button mat-menu-item routerLink="/wallet">Quản lý ví</button>
            <button mat-menu-item (click)="disconnectWallet()">Ngắt kết nối</button>
          </mat-menu>
        </div>
        
        <ng-template #connectButton>
          <button mat-raised-button color="accent" routerLink="/wallet">
            <mat-icon>account_balance_wallet</mat-icon>
            Tạo ví
          </button>
        </ng-template>
      </div>
    </mat-toolbar>
    
    <main class="min-h-screen bg-gray-50">
      <router-outlet></router-outlet>
    </main>
  `,
  styles: [`
    .wallet-connected {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
  `]
})
export class AppComponent implements OnInit {
  walletInfo$: Observable<WalletInfo | null>;

  constructor(private walletService: AutoWalletService) {
    this.walletInfo$ = this.walletService.walletInfo$;
  }

  ngOnInit() {
    // Không cần làm gì đặc biệt, service sẽ tự động quản lý state
  }

  disconnectWallet() {
    this.walletService.disconnectWallet();
  }
}
