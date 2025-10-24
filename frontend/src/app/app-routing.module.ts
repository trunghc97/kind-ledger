import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { CampaignListComponent } from './components/campaign-list/campaign-list.component';
import { CampaignDetailComponent } from './components/campaign-detail/campaign-detail.component';
import { CreateCampaignComponent } from './components/create-campaign/create-campaign.component';
import { DonateComponent } from './components/donate/donate.component';

const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'campaigns', component: CampaignListComponent },
  { path: 'campaigns/:id', component: CampaignDetailComponent },
  { path: 'create-campaign', component: CreateCampaignComponent },
  { path: 'donate/:id', component: DonateComponent },
  { path: '**', redirectTo: '/dashboard' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
