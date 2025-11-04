import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { CampaignListComponent } from './components/campaign-list/campaign-list.component';
import { CampaignDetailComponent } from './components/campaign-detail/campaign-detail.component';
import { CreateCampaignComponent } from './components/create-campaign/create-campaign.component';
import { DonateComponent } from './components/donate/donate.component';
import { LoginComponent } from './components/login/login.component';
import { RegisterComponent } from './components/register/register.component';
import { AuthGuard } from './guards/auth.guard';
import { DepositComponent } from './components/deposit/deposit.component';
import { WalletLinkBankComponent } from './components/wallet-link-bank/wallet-link-bank.component';
import { TransferTokenComponent } from './components/transfer-token/transfer-token.component';

const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'campaigns', component: CampaignListComponent, canActivate: [AuthGuard] },
  { path: 'campaigns/:id', component: CampaignDetailComponent, canActivate: [AuthGuard] },
  { path: 'create-campaign', component: CreateCampaignComponent, canActivate: [AuthGuard] },
  { path: 'donate/:id', component: DonateComponent, canActivate: [AuthGuard] },
  { path: 'deposit', component: DepositComponent },
  { path: 'transfer', component: TransferTokenComponent },
  { path: 'link-bank', component: WalletLinkBankComponent },
  { path: '**', redirectTo: '/login' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
