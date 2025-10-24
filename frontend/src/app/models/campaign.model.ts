export interface Campaign {
  id: number;
  name: string;
  description: string;
  targetAmount: number;
  raisedAmount: number;
  status: string;
  deadline: string;
  evidenceHash?: string;
  creatorWallet: string;
  createdAt: string;
  updatedAt: string;
}

export interface CampaignProgress {
  campaignId: number;
  totalRaised: number;
  progressPercentage: number;
}
