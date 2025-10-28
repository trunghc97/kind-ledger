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
          // Merge pending campaigns from localStorage (chưa on-chain)
          let merged = response.data || [];
          try {
            const pendingRaw = localStorage.getItem('pendingCampaigns');
            const pending = pendingRaw ? JSON.parse(pendingRaw) : [];
            // Loại bỏ pending đã có on-chain (id trùng)
            const existingIds = new Set(merged.map((c: any) => c.id));
            const pendingFiltered = pending.filter((p: any) => !existingIds.has(p.id));
            // Đánh dấu pending để UI xử lý
            pendingFiltered.forEach((p: any) => p.status = 'PENDING');
            merged = [...pendingFiltered, ...merged];
          } catch (e) {
            console.warn('Không thể merge pendingCampaigns:', e);
          }
          this.campaigns = merged;
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
