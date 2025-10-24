import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterModule } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { WalletService } from './services/wallet.service';
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
        
        <div *ngIf="walletAddress$ | async as address; else connectButton">
          <button mat-button [matMenuTriggerFor]="walletMenu" class="wallet-connected">
            <mat-icon>account_balance_wallet</mat-icon>
            {{ address | slice:0:6 }}...{{ address | slice:-4 }}
          </button>
          <mat-menu #walletMenu="matMenu">
            <button mat-menu-item routerLink="/wallet">Ví của tôi</button>
            <button mat-menu-item (click)="disconnectWallet()">Ngắt kết nối</button>
          </mat-menu>
        </div>
        
        <ng-template #connectButton>
          <button mat-raised-button color="accent" (click)="connectWallet()">
            <mat-icon>account_balance_wallet</mat-icon>
            Kết nối ví
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
  walletAddress$: Observable<string | null>;

  constructor(private walletService: WalletService) {
    this.walletAddress$ = this.walletService.walletAddress$;
  }

  ngOnInit() {
    this.walletService.getWalletAddress().then(address => {
      if (address) {
        // Wallet address will be automatically updated through the service
        // No need to manually call next() on the observable
      }
    });
  }

  async connectWallet() {
    try {
      await this.walletService.connectWallet();
      await this.walletService.switchNetwork();
    } catch (error) {
      console.error('Error connecting wallet:', error);
    }
  }

  disconnectWallet() {
    this.walletService.disconnectWallet();
  }
}
