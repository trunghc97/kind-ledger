import { Component, OnInit } from '@angular/core';
import { CampaignService, Campaign } from '../../services/campaign.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  campaigns: Campaign[] = [];
  totalDonations: number = 0;
  loading = true;
  error: string | null = null;

  constructor(private campaignService: CampaignService) { }

  ngOnInit(): void {
    this.loadDashboard();
  }

  loadDashboard(): void {
    this.loading = true;
    this.error = null;

    this.campaignService.getAllCampaigns().subscribe({
      next: (response: any) => {
        if (response.success) {
          this.campaigns = response.data;
          this.calculateTotalDonations();
        } else {
          this.error = response.message;
        }
        this.loading = false;
      },
      error: (err: any) => {
        this.error = 'Không thể tải dữ liệu từ blockchain';
        this.loading = false;
        console.error('Error loading dashboard:', err);
      }
    });
  }

  calculateTotalDonations(): void {
    this.totalDonations = this.campaigns.reduce((total, campaign) => total + campaign.raised, 0);
  }

  getProgressPercentage(campaign: Campaign): number {
    if (campaign.goal === 0) return 0;
    return Math.min((campaign.raised / campaign.goal) * 100, 100);
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(amount);
  }

  refresh(): void {
    this.loadDashboard();
  }

  getCompletedCampaignsCount(): number {
    return this.campaigns.filter(c => c.status === 'COMPLETED').length;
  }
}
