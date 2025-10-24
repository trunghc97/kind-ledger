import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { GatewayService } from '../../services/gateway.service';
import { Campaign } from '../../models/campaign.model';

@Component({
  selector: 'app-campaign-detail',
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
    <div class="container mx-auto px-4 py-8" *ngIf="campaign; else loading">
      <div class="max-w-4xl mx-auto">
        <!-- Campaign Header -->
        <mat-card class="mb-6">
          <mat-card-header>
            <mat-card-title class="text-2xl">{{ campaign.name }}</mat-card-title>
            <mat-card-subtitle>
              Tạo bởi: {{ campaign.creatorWallet | slice:0:6 }}...{{ campaign.creatorWallet | slice:-4 }}
            </mat-card-subtitle>
          </mat-card-header>
          <mat-card-content>
            <p class="text-gray-700 mb-4">{{ campaign.description }}</p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Progress Section -->
              <div>
                <h3 class="text-lg font-semibold mb-4">Tiến độ ủng hộ</h3>
                <div class="space-y-3">
                  <div class="flex justify-between">
                    <span>Đã ủng hộ</span>
                    <span class="font-semibold">{{ campaign.raisedAmount | currency:'VND':'symbol':'1.0-0':'vi' }}</span>
                  </div>
                  <div class="flex justify-between">
                    <span>Mục tiêu</span>
                    <span class="font-semibold">{{ campaign.targetAmount | currency:'VND':'symbol':'1.0-0':'vi' }}</span>
                  </div>
                  
                  <mat-progress-bar 
                    mode="determinate" 
                    [value]="getProgressPercentage()"
                    class="progress-bar">
                  </mat-progress-bar>
                  
                  <div class="text-center text-sm text-gray-600">
                    {{ getProgressPercentage() | number:'1.1-1' }}% hoàn thành
                  </div>
                </div>
              </div>
              
              <!-- Campaign Info -->
              <div>
                <h3 class="text-lg font-semibold mb-4">Thông tin chiến dịch</h3>
                <div class="space-y-2">
                  <div class="flex justify-between">
                    <span>Trạng thái</span>
                    <mat-chip [color]="campaign.status === 'ACTIVE' ? 'primary' : 'warn'">
                      {{ campaign.status === 'ACTIVE' ? 'Đang hoạt động' : 'Đã kết thúc' }}
                    </mat-chip>
                  </div>
                  <div class="flex justify-between">
                    <span>Hết hạn</span>
                    <span>{{ campaign.deadline | date:'dd/MM/yyyy' }}</span>
                  </div>
                  <div class="flex justify-between">
                    <span>Tạo lúc</span>
                    <span>{{ campaign.createdAt | date:'dd/MM/yyyy HH:mm' }}</span>
                  </div>
                </div>
              </div>
            </div>
          </mat-card-content>
          
          <mat-card-actions class="flex justify-between p-4">
            <button mat-button routerLink="/campaigns">
              <mat-icon>arrow_back</mat-icon>
              Quay lại
            </button>
            <button mat-raised-button color="accent" routerLink="/donate" [queryParams]="{campaignId: campaign.id}">
              <mat-icon>favorite</mat-icon>
              Ủng hộ ngay
            </button>
          </mat-card-actions>
        </mat-card>
        
        <!-- Evidence Section -->
        <mat-card *ngIf="campaign.evidenceHash" class="mb-6">
          <mat-card-header>
            <mat-card-title>Chứng từ minh bạch</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="bg-green-50 p-4 rounded-lg">
              <div class="flex items-center">
                <mat-icon class="text-green-500 mr-2">check_circle</mat-icon>
                <div>
                  <p class="text-sm text-green-800">
                    <strong>Hash chứng từ:</strong> {{ campaign.evidenceHash }}
                  </p>
                  <p class="text-sm text-green-600 mt-1">
                    Chứng từ được lưu trữ trên IPFS để đảm bảo tính minh bạch
                  </p>
                </div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>
    </div>

    <ng-template #loading>
      <div class="text-center py-8">
        <mat-icon class="text-6xl text-gray-400">schedule</mat-icon>
        <p class="text-lg text-gray-600 mt-4">Đang tải thông tin chiến dịch...</p>
      </div>
    </ng-template>
  `,
  styles: [`
    .progress-bar {
      background: linear-gradient(90deg, #3b82f6, #10b981);
    }
  `]
})
export class CampaignDetailComponent implements OnInit {
  campaign: Campaign | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private gatewayService: GatewayService
  ) {}

  ngOnInit() {
    const campaignId = this.route.snapshot.paramMap.get('id');
    if (campaignId) {
      this.loadCampaign(+campaignId);
    }
  }

  loadCampaign(id: number) {
    this.gatewayService.getCampaignById(id).subscribe({
      next: (campaign) => {
        this.campaign = campaign;
      },
      error: (error) => {
        console.error('Error loading campaign:', error);
        this.router.navigate(['/campaigns']);
      }
    });
  }

  getProgressPercentage(): number {
    if (!this.campaign) return 0;
    return (this.campaign.raisedAmount / this.campaign.targetAmount) * 100;
  }
}
