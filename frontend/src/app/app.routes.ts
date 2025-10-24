import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/campaigns',
    pathMatch: 'full'
  },
  {
    path: 'campaigns',
    loadComponent: () => import('./pages/campaign-list/campaign-list.component').then(m => m.CampaignListComponent)
  },
  {
    path: 'campaign/:id',
    loadComponent: () => import('./pages/campaign-detail/campaign-detail.component').then(m => m.CampaignDetailComponent)
  },
  {
    path: 'donate',
    loadComponent: () => import('./pages/donate/donate.component').then(m => m.DonateComponent)
  },
  {
    path: 'buy-item',
    loadComponent: () => import('./pages/buy-item/buy-item.component').then(m => m.BuyItemComponent)
  },
  {
    path: 'wallet',
    loadComponent: () => import('./pages/wallet/wallet.component').then(m => m.WalletComponent)
  }
];
