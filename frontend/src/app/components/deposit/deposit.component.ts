import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { GatewayService } from '../../services/gateway.service';

@Component({
  selector: 'app-deposit',
  templateUrl: './deposit.component.html',
  styleUrls: ['./deposit.component.scss']
})
export class DepositComponent {
  amount: number|null = null;
  loading = false;
  errorMsg = '';

  constructor(
    private auth: AuthService,
    private gateway: GatewayService,
    private router: Router
  ) {}

  submitDeposit() {
    this.errorMsg = '';
    if (!this.amount || this.amount < 1000) {
      this.errorMsg = 'Số tiền phải lớn hơn 1,000 VND';
      return;
    }
    this.loading = true;
    const walletAddress = this.auth.getCurrentUser()?.walletAddress;
    if (!walletAddress) { this.errorMsg = 'Không tìm thấy ví'; this.loading = false; return; }
    this.gateway.deposit(walletAddress, this.amount).subscribe({
      next: () => {
        this.loading = false;
        this.router.navigate(['/']);
      },
      error: (err) => {
        this.loading = false;
        this.errorMsg = 'Nạp tiền thất bại: ' + (err.error?.message || err.message || 'Lỗi không xác định');
      }
    });
  }
}
