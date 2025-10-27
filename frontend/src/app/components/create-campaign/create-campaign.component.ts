import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { CampaignService, Campaign } from '../../services/campaign.service';

@Component({
  selector: 'app-create-campaign',
  templateUrl: './create-campaign.component.html',
  styleUrls: ['./create-campaign.component.scss']
})
export class CreateCampaignComponent implements OnInit {
  campaignForm: FormGroup;
  loading = false;
  error: string | null = null;
  success = false;

  constructor(
    private fb: FormBuilder,
    private campaignService: CampaignService,
    private router: Router
  ) {
    this.campaignForm = this.fb.group({
      id: ['', [Validators.required, Validators.minLength(3)]],
      name: ['', [Validators.required, Validators.minLength(5)]],
      description: ['', [Validators.required, Validators.minLength(10)]],
      owner: ['', [Validators.required, Validators.minLength(3)]],
      goal: ['', [Validators.required, Validators.min(1000000)]]
    });
  }

  ngOnInit(): void {
    // Generate a default campaign ID
    const campaignId = 'campaign-' + Date.now();
    this.campaignForm.patchValue({ id: campaignId });
  }

  onSubmit(): void {
    if (this.campaignForm.valid) {
      this.loading = true;
      this.error = null;
      this.success = false;

      const campaignData: Campaign = {
        id: this.campaignForm.value.id,
        name: this.campaignForm.value.name,
        description: this.campaignForm.value.description,
        owner: this.campaignForm.value.owner,
        goal: this.campaignForm.value.goal,
        raised: 0,
        status: 'OPEN',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        donors: []
      };

      this.campaignService.createCampaign(campaignData).subscribe({
        next: (response: any) => {
          if (response.success) {
            this.success = true;
            this.loading = false;
            setTimeout(() => {
              this.router.navigate(['/campaigns', response.data.id]);
            }, 2000);
          } else {
            this.error = response.message;
            this.loading = false;
          }
        },
        error: (err: any) => {
          this.error = 'Không thể tạo chiến dịch. Vui lòng thử lại.';
          this.loading = false;
          console.error('Error creating campaign:', err);
        }
      });
    } else {
      this.markFormGroupTouched();
    }
  }

  markFormGroupTouched(): void {
    Object.keys(this.campaignForm.controls).forEach(key => {
      const control = this.campaignForm.get(key);
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
    const field = this.campaignForm.get(fieldName);
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
      'id': 'Mã chiến dịch',
      'name': 'Tên chiến dịch',
      'description': 'Mô tả',
      'owner': 'Tổ chức',
      'goal': 'Mục tiêu'
    };
    return labels[fieldName] || fieldName;
  }
}
