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
    fromWallet: ['', [Validators.required]],
    toWallet: ['', [Validators.required]],
    amount: [null as any, [Validators.required, Validators.min(0.0000001)]]
  });

  private apiBase = environment.apiUrl + '/api/v1';

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

    // Step 1: kiểm tra active của 2 ví
    this.http.get(`${this.apiBase}/wallet/${body.fromWallet}`).subscribe({
      next: (from: any) => {
        this.http.get(`${this.apiBase}/wallet/${body.toWallet}`).subscribe({
          next: (to: any) => {
            if (!from?.active || !to?.active) {
              this.message = '❌ Cả hai ví phải ở trạng thái active.';
              this.loading = false;
              return;
            }

            // Step 2: Gọi transfer
            this.http.post(`${this.apiBase}/transfer`, {
              fromWallet: body.fromWallet,
              toWallet: body.toWallet,
              amount: Number(body.amount)
            }).subscribe({
              next: (res: any) => {
                this.result = res;
                this.message = res?.message || 'Transfer thành công';
                this.explorerUrl = res?.explorerUrl || null;

                // Step 3: Kiểm tra trace blockchain
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
          },
          error: () => {
            this.message = '❌ Không thể kiểm tra ví đích.';
            this.loading = false;
          }
        });
      },
      error: () => {
        this.message = '❌ Không thể kiểm tra ví nguồn.';
        this.loading = false;
      }
    });
  }
}
