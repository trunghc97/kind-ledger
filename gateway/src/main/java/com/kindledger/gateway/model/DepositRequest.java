package com.kindledger.gateway.model;

import java.math.BigDecimal;

public class DepositRequest {
    private BigDecimal amount;
    private String walletAddress;

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getWalletAddress() { return walletAddress; }
    public void setWalletAddress(String walletAddress) { this.walletAddress = walletAddress; }
}
