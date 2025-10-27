import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { CampaignService, Campaign, DonationRequest } from '../../services/campaign.service';

@Component({
  selector: 'app-donate',
  templateUrl: './donate.component.html',
  styleUrls: ['./donate.component.scss']
})
export class DonateComponent implements OnInit {
  donationForm: FormGroup;
  campaign: Campaign | null = null;
  loading = false;
  error: string | null = null;
  success = false;
  campaignId: string = '';

  constructor(
    private fb: FormBuilder,
    private campaignService: CampaignService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.donationForm = this.fb.group({
      donorId: ['', [Validators.required, Validators.minLength(3)]],
      donorName: ['', [Validators.required, Validators.minLength(3)]],
      amount: ['', [Validators.required, Validators.min(10000)]]
    });
  }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      this.campaignId = params['id'];
      if (this.campaignId) {
        this.loadCampaign();
      }
    });
  }

  loadCampaign(): void {
    this.campaignService.getCampaign(this.campaignId).subscribe({
      next: (response: any) => {
        if (response.success) {
          this.campaign = response.data;
        } else {
          this.error = response.message;
        }
      },
      error: (err: any) => {
        this.error = 'Không thể tải thông tin chiến dịch';
        console.error('Error loading campaign:', err);
      }
    });
  }

  onSubmit(): void {
    if (this.donationForm.valid && this.campaign) {
      this.loading = true;
      this.error = null;
      this.success = false;

      const donationData: DonationRequest = {
        campaignId: this.campaignId,
        donorId: this.donationForm.value.donorId,
        donorName: this.donationForm.value.donorName,
        amount: this.donationForm.value.amount
      };

      this.campaignService.donate(donationData).subscribe({
        next: (response: any) => {
          if (response.success) {
            this.success = true;
            this.loading = false;
            this.campaign = response.data;
            this.donationForm.reset();
            setTimeout(() => {
              this.router.navigate(['/campaigns', this.campaignId]);
            }, 2000);
          } else {
            this.error = response.message;
            this.loading = false;
          }
        },
        error: (err: any) => {
          this.error = 'Không thể xử lý quyên góp. Vui lòng thử lại.';
          this.loading = false;
          console.error('Error processing donation:', err);
        }
      });
    } else {
      this.markFormGroupTouched();
    }
  }

  markFormGroupTouched(): void {
    Object.keys(this.donationForm.controls).forEach(key => {
      const control = this.donationForm.get(key);
      control?.markAsTouched();
    });
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(amount);
  }

  getFieldError(fieldName: string): string {
    const field = this.donationForm.get(fieldName);
    if (field?.errors && field.touched) {
      if (field.errors['required']) {
        return `${this.getFieldLabel(fieldName)} là bắt buộc`;
      }
      if (field.errors['minlength']) {
        return `${this.getFieldLabel(fieldName)} phải có ít nhất ${field.errors['minlength'].requiredLength} ký tự`;
      }
      if (field.errors['min']) {
        return `${this.getFieldLabel(fieldName)} phải lớn hơn ${this.formatCurrency(field.errors['min'].min)}`;
      }
    }
    return '';
  }

  getFieldLabel(fieldName: string): string {
    const labels: { [key: string]: string } = {
      'donorId': 'Mã nhà tài trợ',
      'donorName': 'Tên nhà tài trợ',
      'amount': 'Số tiền quyên góp'
    };
    return labels[fieldName] || fieldName;
  }
}
