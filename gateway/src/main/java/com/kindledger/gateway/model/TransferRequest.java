package com.kindledger.gateway.model;

import java.math.BigDecimal;

public class TransferRequest {
    private String fromWalletAddress;
    private String toWalletAddress;
    private BigDecimal amount;

    public String getFromWalletAddress() { return fromWalletAddress; }
    public void setFromWalletAddress(String fromWalletAddress) { this.fromWalletAddress = fromWalletAddress; }

    public String getToWalletAddress() { return toWalletAddress; }
    public void setToWalletAddress(String toWalletAddress) { this.toWalletAddress = toWalletAddress; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
}
