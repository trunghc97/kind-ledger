export interface Transaction {
  id: number;
  txHash: string;
  walletAddress: string;
  transactionType: 'MINT' | 'BURN' | 'DONATE' | 'BUY_ITEM' | 'REDEEM';
  amount: number;
  campaignId?: number;
  status: string;
  createdAt: string;
}

export interface WalletBalance {
  address: string;
  cVndBalance: number;
  status: string;
}

export interface DonateRequest {
  walletAddress: string;
  campaignId: number;
  amount: number;
  message?: string;
}

export interface MintRequest {
  walletAddress: string;
  accountNo: string;
  amount: number;
}

export interface TransactionResponse {
  txHash: string;
  status: string;
  amount?: number;
  walletAddress?: string;
  transactionType?: string;
  campaignId?: number;
  createdAt?: string;
  message: string;
}
