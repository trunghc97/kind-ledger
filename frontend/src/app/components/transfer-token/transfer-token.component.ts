import { Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-transfer-token',
  templateUrl: './transfer-token.component.html',
  styleUrls: ['./transfer-token.component.scss']
})
export class TransferTokenComponent {
  loading = false;
  message: string | null = null;
  explorerUrl: string | null = null;
  blockStatus: string | null = null;
  result: any = null;

  form = this.fb.group({
    // Bỏ fromWallet: ví nguồn mặc định theo user đăng nhập
    toWallet: ['', [Validators.required]],
    amount: [null as any, [Validators.required, Validators.min(0.0000001)]]
  });

  private apiBase = environment.apiUrl + '/v1';

  constructor(private fb: FormBuilder, private http: HttpClient) {}

  transfer(): void {
    if (this.form.invalid) {
      this.message = '❌ Vui lòng nhập đầy đủ thông tin hợp lệ.';
      return;
    }
    this.loading = true;
    this.message = null;
    this.result = null;
    this.explorerUrl = null;
    this.blockStatus = null;

    const body = this.form.value as any;

    // Gọi transfer: backend sẽ kiểm tra ví đích active và suy ra ví nguồn từ phiên đăng nhập
    this.http.post(`${this.apiBase}/transfer`, {
      toWalletAddress: body.toWallet,
      amount: Number(body.amount)
    }).subscribe({
      next: (res: any) => {
        this.result = res;
        this.message = res?.message || 'Transfer thành công';
        this.explorerUrl = res?.explorerUrl || null;

        if (res?.txId) {
          this.http.get(`${this.apiBase}/token/trace/${res.txId}`).subscribe({
            next: (trace: any) => {
              this.blockStatus = trace?.blockchainStatus || null;
              this.loading = false;
            },
            error: () => {
              this.blockStatus = null;
              this.loading = false;
            }
          });
        } else {
          this.loading = false;
        }
      },
      error: (err) => {
        this.message = err?.error?.message || 'Transfer failed';
        this.loading = false;
      }
    });
  }
}
