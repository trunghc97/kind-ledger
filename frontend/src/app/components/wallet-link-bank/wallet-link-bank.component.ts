import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { AuthService } from '../../services/auth.service';
import { GatewayService } from '../../services/gateway.service';

@Component({
  selector: 'app-wallet-link-bank',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatSnackBarModule
  ],
  template: `
    <mat-card>
      <mat-card-header>
        <mat-card-title>Liên kết tài khoản ngân hàng</mat-card-title>
      </mat-card-header>
      <mat-card-content>
        <form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-4">
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Số tài khoản</mat-label>
            <input matInput formControlName="accountNumber" placeholder="Nhập số tài khoản">
          </mat-form-field>
          <div class="flex justify-end">
            <button mat-raised-button color="primary" type="submit" [disabled]="!form.valid || loading">
              {{ loading ? 'Đang liên kết...' : 'Liên kết' }}
            </button>
          </div>
        </form>
      </mat-card-content>
    </mat-card>
  `
})
export class WalletLinkBankComponent {
  form: FormGroup;
  loading = false;

  constructor(
    private fb: FormBuilder,
    private auth: AuthService,
    private gateway: GatewayService,
    private snack: MatSnackBar
  ) {
    this.form = this.fb.group({
      accountNumber: ['', Validators.required]
    });
  }

  onSubmit() {
    const user = this.auth.getCurrentUser();
    if (!user) {
      this.snack.open('Vui lòng đăng nhập', 'Đóng', { duration: 3000 });
      return;
    }
    this.loading = true;
    this.gateway.linkBank(user.id, this.form.value.accountNumber).subscribe({
      next: () => {
        this.snack.open('Liên kết ngân hàng thành công! Ví đã ACTIVE', 'Đóng', { duration: 4000 });
        this.form.reset();
      },
      error: (err) => {
        this.snack.open('Liên kết thất bại: ' + (err?.error?.message || 'Unknown'), 'Đóng', { duration: 4000 });
      },
      complete: () => this.loading = false
    });
  }
}
