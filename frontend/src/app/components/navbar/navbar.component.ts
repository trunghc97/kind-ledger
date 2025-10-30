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
    if (!this.currentUser || !this.currentUser.walletId) return;
    // Dùng đúng WalletId backend trả ra
    const walletAddress = this.currentUser.walletId;
    this.gateway.getWalletBalance(walletAddress).subscribe({
      next: (res: any) => {
        this.walletBalance = res?.cVndBalance ?? 0;
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

  onDeposit() {
    this.showWalletAction = false;
    this.fetchWallet();
  }

  toggleCollapse() {
    this.isCollapsed = !this.isCollapsed;
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
