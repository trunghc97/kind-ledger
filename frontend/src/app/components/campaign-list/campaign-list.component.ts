import { Component, OnInit } from '@angular/core';
import { CampaignService, Campaign } from '../../services/campaign.service';

@Component({
  selector: 'app-campaign-list',
  templateUrl: './campaign-list.component.html',
  styleUrls: ['./campaign-list.component.scss']
})
export class CampaignListComponent implements OnInit {
  campaigns: Campaign[] = [];
  loading = true;
  error: string | null = null;

  constructor(private campaignService: CampaignService) { }

  ngOnInit(): void {
    this.loadCampaigns();
  }

  loadCampaigns(): void {
    this.loading = true;
    this.error = null;

    this.campaignService.getAllCampaigns().subscribe({
      next: (response: any) => {
        if (response.success) {
          this.campaigns = response.data;
        } else {
          this.error = response.message;
        }
        this.loading = false;
      },
      error: (err: any) => {
        this.error = 'Không thể tải danh sách chiến dịch';
        this.loading = false;
        console.error('Error loading campaigns:', err);
      }
    });
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
    this.loadCampaigns();
  }
}
