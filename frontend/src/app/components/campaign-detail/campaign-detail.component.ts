import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { CampaignService, Campaign } from '../../services/campaign.service';

@Component({
  selector: 'app-campaign-detail',
  templateUrl: './campaign-detail.component.html',
  styleUrls: ['./campaign-detail.component.scss']
})
export class CampaignDetailComponent implements OnInit {
  campaign: Campaign | null = null;
  loading = true;
  error: string | null = null;

  constructor(
    private campaignService: CampaignService,
    private route: ActivatedRoute
  ) { }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      const campaignId = params['id'];
      if (campaignId) {
        this.loadCampaign(campaignId);
      }
    });
  }

  loadCampaign(id: string): void {
    this.loading = true;
    this.error = null;

    this.campaignService.getCampaign(id).subscribe({
      next: (response) => {
        if (response.success) {
          this.campaign = response.data;
        } else {
          this.error = response.message;
        }
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Không thể tải thông tin chiến dịch';
        this.loading = false;
        console.error('Error loading campaign:', err);
      }
    });
  }

  getProgressPercentage(): number {
    if (!this.campaign || this.campaign.goal === 0) return 0;
    return Math.min((this.campaign.raised / this.campaign.goal) * 100, 100);
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(amount);
  }

  refresh(): void {
    if (this.campaign) {
      this.loadCampaign(this.campaign.id);
    }
  }
}
