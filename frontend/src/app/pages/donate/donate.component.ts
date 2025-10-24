import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { ActivatedRoute, Router } from '@angular/router';
import { GatewayService } from '../../services/gateway.service';
import { AutoWalletService } from '../../services/auto-wallet.service';
import { Campaign } from '../../models/campaign.model';

@Component({
  selector: 'app-donate',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatSelectModule,
    MatSnackBarModule
  ],
  template: `
    <div class="container mx-auto px-4 py-8 max-w-2xl">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-gray-800 mb-4">Ủng hộ thiện nguyện</h1>
        <p class="text-gray-600">Hỗ trợ các chiến dịch thiện nguyện với cVND minh bạch</p>
      </div>

      <mat-card>
        <mat-card-header>
          <mat-card-title>Thông tin ủng hộ</mat-card-title>
        </mat-card-header>
        
        <mat-card-content>
          <form [formGroup]="donateForm" (ngSubmit)="onSubmit()" class="space-y-4">
            <mat-form-field appearance="outline" class="w-full">
              <mat-label>Chọn chiến dịch</mat-label>
              <mat-select formControlName="campaignId" required>
                <mat-option *ngFor="let campaign of campaigns" [value]="campaign.id">
                  {{ campaign.name }}
                </mat-option>
              </mat-select>
            </mat-form-field>

            <mat-form-field appearance="outline" class="w-full">
              <mat-label>Số tiền ủng hộ (VND)</mat-label>
              <input matInput type="number" formControlName="amount" placeholder="Nhập số tiền">
              <mat-icon matSuffix>attach_money</mat-icon>
            </mat-form-field>

            <mat-form-field appearance="outline" class="w-full">
              <mat-label>Lời nhắn (tùy chọn)</mat-label>
              <textarea matInput formControlName="message" rows="3" placeholder="Gửi lời nhắn đến chiến dịch..."></textarea>
            </mat-form-field>

            <div class="bg-blue-50 p-4 rounded-lg" *ngIf="walletInfo">
              <div class="flex items-center">
                <mat-icon class="text-blue-500 mr-2">info</mat-icon>
                <div>
                  <p class="text-sm text-blue-800">
                    <strong>Tài khoản:</strong> {{ walletInfo.accountNo }}
                  </p>
                  <p class="text-sm text-blue-600 mt-1">
                    <strong>Địa chỉ ví:</strong> {{ walletInfo.walletAddress | slice:0:6 }}...{{ walletInfo.walletAddress | slice:-4 }}
                  </p>
                  <p class="text-sm text-blue-600 mt-1">
                    <strong>Số dư cVND:</strong> {{ walletInfo.balance | currency:'VND':'symbol':'1.0-0':'vi' }}
                  </p>
                  <p class="text-sm text-blue-600 mt-1">
                    <strong>KYC:</strong> {{ walletInfo.kycStatus ? 'Đã xác thực' : 'Chưa xác thực' }}
                  </p>
                </div>
              </div>
            </div>
          </form>
        </mat-card-content>
        
        <mat-card-actions class="flex justify-between p-4">
          <button mat-button routerLink="/campaigns">
            <mat-icon>arrow_back</mat-icon>
            Quay lại
          </button>
          <button 
            mat-raised-button 
            color="accent" 
            (click)="onSubmit()"
            [disabled]="!donateForm.valid || isSubmitting">
            <mat-icon *ngIf="!isSubmitting">favorite</mat-icon>
            <mat-icon *ngIf="isSubmitting" class="animate-spin">refresh</mat-icon>
            {{ isSubmitting ? 'Đang xử lý...' : 'Ủng hộ ngay' }}
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  `
})
export class DonateComponent implements OnInit {
  donateForm: FormGroup;
  campaigns: Campaign[] = [];
  walletInfo: any = null;
  isSubmitting = false;

  constructor(
    private fb: FormBuilder,
    private gatewayService: GatewayService,
    private walletService: AutoWalletService,
    private snackBar: MatSnackBar,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.donateForm = this.fb.group({
      campaignId: ['', Validators.required],
      amount: ['', [Validators.required, Validators.min(1000)]],
      message: ['']
    });
  }

  ngOnInit() {
    // Subscribe to wallet info
    this.walletService.walletInfo$.subscribe((walletInfo: any) => {
      this.walletInfo = walletInfo;
      
      if (!walletInfo) {
        this.snackBar.open('Vui lòng tạo ví trước khi ủng hộ', 'Đóng', { duration: 3000 });
        this.router.navigate(['/wallet']);
        return;
      }
      
      this.loadCampaigns();
    });
    
    // Check for campaign ID in query params
    this.route.queryParams.subscribe(params => {
      if (params['campaignId']) {
        this.donateForm.patchValue({ campaignId: +params['campaignId'] });
      }
    });
  }

  loadCampaigns() {
    this.gatewayService.getActiveCampaigns().subscribe({
      next: (campaigns) => {
        this.campaigns = campaigns;
      },
      error: (error) => {
        console.error('Error loading campaigns:', error);
        this.snackBar.open('Lỗi tải danh sách chiến dịch', 'Đóng', { duration: 3000 });
      }
    });
  }

  loadWalletBalance() {
    // Không cần load balance riêng vì đã có trong walletInfo
  }

  onSubmit() {
    if (this.donateForm.valid && this.walletInfo) {
      this.isSubmitting = true;
      
      const formValue = this.donateForm.value;
      const donateRequest = {
        walletAddress: this.walletInfo.walletAddress,
        campaignId: formValue.campaignId,
        amount: formValue.amount,
        message: formValue.message
      };

      this.gatewayService.donate(donateRequest).subscribe({
        next: (response) => {
          this.snackBar.open('Ủng hộ thành công!', 'Đóng', { duration: 5000 });
          this.router.navigate(['/campaigns']);
        },
        error: (error) => {
          console.error('Error donating:', error);
          this.snackBar.open('Lỗi ủng hộ: ' + error.error?.message, 'Đóng', { duration: 5000 });
        },
        complete: () => {
          this.isSubmitting = false;
        }
      });
    }
  }
}
