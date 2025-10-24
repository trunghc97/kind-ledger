import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { GatewayService } from '../../services/gateway.service';
import { Campaign } from '../../models/campaign.model';

@Component({
  selector: 'app-campaign-list',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule,
    MatChipsModule
  ],
  template: `
    <div class="container mx-auto px-4 py-8">
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gray-800 mb-4">Chiến dịch thiện nguyện</h1>
        <p class="text-lg text-gray-600">Tham gia ủng hộ các chiến dịch thiện nguyện minh bạch</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" *ngIf="campaigns.length > 0; else loading">
        <mat-card *ngFor="let campaign of campaigns" class="campaign-card">
          <mat-card-header>
            <mat-card-title class="text-lg font-semibold">{{ campaign.name }}</mat-card-title>
            <mat-card-subtitle>{{ campaign.creatorWallet | slice:0:6 }}...{{ campaign.creatorWallet | slice:-4 }}</mat-card-subtitle>
          </mat-card-header>
          
          <mat-card-content>
            <p class="text-gray-600 mb-4">{{ campaign.description }}</p>
            
            <div class="mb-4">
              <div class="flex justify-between text-sm text-gray-600 mb-2">
                <span>Đã ủng hộ</span>
                <span>{{ campaign.raisedAmount | currency:'VND':'symbol':'1.0-0':'vi' }}</span>
              </div>
              <div class="flex justify-between text-sm text-gray-600 mb-2">
                <span>Mục tiêu</span>
                <span>{{ campaign.targetAmount | currency:'VND':'symbol':'1.0-0':'vi' }}</span>
              </div>
              
              <mat-progress-bar 
                mode="determinate" 
                [value]="getProgressPercentage(campaign)"
                class="progress-bar">
              </mat-progress-bar>
              
              <div class="text-center mt-2 text-sm text-gray-600">
                {{ getProgressPercentage(campaign) | number:'1.1-1' }}% hoàn thành
              </div>
            </div>
            
            <div class="flex items-center justify-between">
              <mat-chip-set>
                <mat-chip [color]="campaign.status === 'ACTIVE' ? 'primary' : 'warn'">
                  {{ campaign.status === 'ACTIVE' ? 'Đang hoạt động' : 'Đã kết thúc' }}
                </mat-chip>
              </mat-chip-set>
              
              <span class="text-sm text-gray-500">
                Hết hạn: {{ campaign.deadline | date:'dd/MM/yyyy' }}
              </span>
            </div>
          </mat-card-content>
          
          <mat-card-actions class="flex justify-between">
            <button mat-button color="primary" [routerLink]="['/campaign', campaign.id]">
              <mat-icon>visibility</mat-icon>
              Xem chi tiết
            </button>
            <button mat-raised-button color="accent" [routerLink]="['/donate']" [queryParams]="{campaignId: campaign.id}">
              <mat-icon>favorite</mat-icon>
              Ủng hộ ngay
            </button>
          </mat-card-actions>
        </mat-card>
      </div>

      <ng-template #loading>
        <div class="text-center py-8">
          <mat-icon class="text-6xl text-gray-400">schedule</mat-icon>
          <p class="text-lg text-gray-600 mt-4">Đang tải danh sách chiến dịch...</p>
        </div>
      </ng-template>
    </div>
  `,
  styles: [`
    .campaign-card {
      transition: transform 0.2s ease-in-out;
    }
    
    .campaign-card:hover {
      transform: translateY(-2px);
    }
    
    .progress-bar {
      background: linear-gradient(90deg, #3b82f6, #10b981);
    }
  `]
})
export class CampaignListComponent implements OnInit {
  campaigns: Campaign[] = [];

  constructor(private gatewayService: GatewayService) {}

  ngOnInit() {
    this.loadCampaigns();
  }

  loadCampaigns() {
    this.gatewayService.getActiveCampaigns().subscribe({
      next: (campaigns) => {
        this.campaigns = campaigns;
      },
      error: (error) => {
        console.error('Error loading campaigns:', error);
      }
    });
  }

  getProgressPercentage(campaign: Campaign): number {
    return (campaign.raisedAmount / campaign.targetAmount) * 100;
  }
}
