import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService, User } from '../../services/auth.service';
import { GatewayService } from '../../services/gateway.service';
import { WalletLinkBankComponent } from '../wallet-link-bank/wallet-link-bank.component';

@Component({
  selector: 'app-navbar',
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss']
})
export class NavbarComponent implements OnInit {
  isCollapsed = true;
  currentUser: User | null = null;

  walletBalance: number = 0;
  walletActive: boolean = false;
  loadingWallet = false;

  showWalletAction = false;
  showLinkBank = false; // true: hiển thị link, false: nạp tiền

  constructor(
    private authService: AuthService,
    private gateway: GatewayService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.authService.currentUser$.subscribe(user => {
      this.currentUser = user;
      if (user) this.fetchWallet();
    });
  }

  fetchWallet() {
    this.loadingWallet = true;
    if (!this.currentUser || !this.currentUser.walletAddress) {
      this.loadingWallet = false;
      return;
    }
    const walletAddress = this.currentUser.walletAddress;
    this.gateway.getWalletBalance(walletAddress).subscribe({
      next: (res: any) => {
        this.walletBalance = Number(res?.cVndBalance ?? 0);
        this.walletActive = res?.status === 'ACTIVE';
        this.loadingWallet = false;
      },
      error: () => {
        this.walletBalance = 0; this.walletActive = false; this.loadingWallet = false;
      }
    });
  }

  openWalletAction() {
    if (!this.currentUser) return;
    this.showWalletAction = true;
    if (this.walletActive) {
      this.showLinkBank = false;
    } else {
      this.showLinkBank = true;
    }
  }

  closeWalletAction() { this.showWalletAction = false; }

  onLinkedBankSuccess() {
    this.showWalletAction = false;
    this.fetchWallet();
  }

  onDeposit(form: any) {
    if (!this.currentUser?.walletAddress) return;
    const amount = form.value.amount;
    if (!amount) return;
    this.gateway.deposit(this.currentUser.walletAddress, amount)
      .subscribe({
         next: () => {
           this.showWalletAction = false;
           this.fetchWallet();
         },
         error: err => {
           alert('Nạp tiền thất bại: ' + err);
         }
      });
  }

  toggleCollapse() {
    this.isCollapsed = !this.isCollapsed;
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
