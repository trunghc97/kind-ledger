import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { GatewayService } from '../../services/gateway.service';

@Component({
  selector: 'app-wallet-link-bank',
  templateUrl: './wallet-link-bank.component.html',
  styleUrls: ['./wallet-link-bank.component.scss']
})
export class WalletLinkBankComponent {
  accountNumber = '';
  loading = false;
  errorMsg = '';

  constructor(private auth: AuthService, private gateway: GatewayService, private router: Router) {}

  submitBankLink() {
    this.errorMsg = '';
    if (!this.accountNumber || this.accountNumber.length < 6) {
      this.errorMsg = 'Số tài khoản phải hợp lệ';
      return;
    }
    this.loading = true;
    this.gateway.linkBank(this.accountNumber).subscribe({
      next: () => {
        this.loading = false;
        this.router.navigate(['/']);
      },
      error: (err) => {
        this.loading = false;
        this.errorMsg = 'Liên kết thất bại: ' + (err.error?.message || err.message || 'Lỗi không xác định');
      }
    });
  }
}
