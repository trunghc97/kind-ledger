import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { GatewayService } from '../../services/gateway.service';
import { WalletService } from '../../services/wallet.service';

interface Item {
  id: number;
  name: string;
  description: string;
  price: number;
  imageUrl?: string;
  campaignId: number;
  availableQuantity: number;
}

@Component({
  selector: 'app-buy-item',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatSnackBarModule
  ],
  template: `
    <div class="container mx-auto px-4 py-8">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-gray-800 mb-4">Mua vật phẩm ủng hộ</h1>
        <p class="text-gray-600">Mua các vật phẩm ủng hộ với cVND minh bạch</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" *ngIf="items.length > 0; else loading">
        <mat-card *ngFor="let item of items" class="item-card">
          <img *ngIf="item.imageUrl" [src]="item.imageUrl" [alt]="item.name" class="w-full h-48 object-cover">
          <div *ngIf="!item.imageUrl" class="w-full h-48 bg-gray-200 flex items-center justify-center">
            <mat-icon class="text-6xl text-gray-400">image</mat-icon>
          </div>
          
          <mat-card-header>
            <mat-card-title>{{ item.name }}</mat-card-title>
            <mat-card-subtitle>{{ item.description }}</mat-card-subtitle>
          </mat-card-header>
          
          <mat-card-content>
            <div class="flex justify-between items-center mb-4">
              <span class="text-2xl font-bold text-green-600">
                {{ item.price | currency:'VND':'symbol':'1.0-0':'vi' }}
              </span>
              <span class="text-sm text-gray-500">
                Còn lại: {{ item.availableQuantity }}
              </span>
            </div>
            
            <div class="bg-blue-50 p-3 rounded-lg mb-4">
              <div class="flex items-center">
                <mat-icon class="text-blue-500 mr-2">info</mat-icon>
                <div>
                  <p class="text-sm text-blue-800">
                    <strong>Ví đã kết nối:</strong> {{ walletAddress | slice:0:6 }}...{{ walletAddress | slice:-4 }}
                  </p>
                  <p class="text-sm text-blue-600 mt-1">
                    Số dư: {{ walletBalance | currency:'VND':'symbol':'1.0-0':'vi' }}
                  </p>
                </div>
              </div>
            </div>
          </mat-card-content>
          
          <mat-card-actions class="flex justify-between">
            <button mat-button color="primary" [routerLink]="['/campaign', item.campaignId]">
              <mat-icon>visibility</mat-icon>
              Xem chiến dịch
            </button>
            <button 
              mat-raised-button 
              color="accent" 
              (click)="buyItem(item)"
              [disabled]="item.availableQuantity <= 0 || isBuying">
              <mat-icon *ngIf="!isBuying">shopping_cart</mat-icon>
              <mat-icon *ngIf="isBuying" class="animate-spin">refresh</mat-icon>
              {{ isBuying ? 'Đang xử lý...' : 'Mua ngay' }}
            </button>
          </mat-card-actions>
        </mat-card>
      </div>

      <ng-template #loading>
        <div class="text-center py-8">
          <mat-icon class="text-6xl text-gray-400">hourglass_empty</mat-icon>
          <p class="text-lg text-gray-600 mt-4">Đang tải danh sách vật phẩm...</p>
        </div>
      </ng-template>
    </div>
  `,
  styles: [`
    .item-card {
      transition: transform 0.2s ease-in-out;
    }
    
    .item-card:hover {
      transform: translateY(-2px);
    }
  `]
})
export class BuyItemComponent implements OnInit {
  items: Item[] = [];
  walletAddress: string | null = null;
  walletBalance: number = 0;
  isBuying = false;

  constructor(
    private gatewayService: GatewayService,
    private walletService: WalletService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit() {
    this.walletAddress = this.walletService.getCurrentWalletAddress();
    
    if (!this.walletAddress) {
      this.snackBar.open('Vui lòng kết nối ví trước', 'Đóng', { duration: 3000 });
      return;
    }

    this.loadItems();
    this.loadWalletBalance();
  }

  loadItems() {
    // Mock data for demo
    this.items = [
      {
        id: 1,
        name: 'Áo ấm',
        description: 'Áo ấm cho trẻ em nghèo',
        price: 50000,
        campaignId: 1,
        availableQuantity: 100
      },
      {
        id: 2,
        name: 'Sách vở',
        description: 'Bộ sách vở học tập',
        price: 30000,
        campaignId: 1,
        availableQuantity: 200
      },
      {
        id: 3,
        name: 'Bánh kẹo',
        description: 'Bánh kẹo cho trẻ em',
        price: 20000,
        campaignId: 1,
        availableQuantity: 500
      },
      {
        id: 4,
        name: 'Gạch xây dựng',
        description: 'Gạch xây dựng trường học',
        price: 100000,
        campaignId: 2,
        availableQuantity: 1000
      },
      {
        id: 5,
        name: 'Xi măng',
        description: 'Xi măng xây dựng',
        price: 50000,
        campaignId: 2,
        availableQuantity: 500
      },
      {
        id: 6,
        name: 'Thực phẩm',
        description: 'Thực phẩm cho người già',
        price: 100000,
        campaignId: 3,
        availableQuantity: 100
      }
    ];
  }

  loadWalletBalance() {
    if (this.walletAddress) {
      this.gatewayService.getWalletBalance(this.walletAddress).subscribe({
        next: (balance) => {
          this.walletBalance = balance.cVndBalance;
        },
        error: (error) => {
          console.error('Error loading wallet balance:', error);
        }
      });
    }
  }

  buyItem(item: Item) {
    if (!this.walletAddress) {
      this.snackBar.open('Vui lòng kết nối ví trước', 'Đóng', { duration: 3000 });
      return;
    }

    if (this.walletBalance < item.price) {
      this.snackBar.open('Số dư không đủ để mua vật phẩm này', 'Đóng', { duration: 3000 });
      return;
    }

    this.isBuying = true;

    // Simulate buying process
    setTimeout(() => {
      this.snackBar.open(`Mua ${item.name} thành công!`, 'Đóng', { duration: 5000 });
      this.isBuying = false;
      this.loadWalletBalance();
    }, 2000);
  }
}
