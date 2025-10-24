package com.mbbank.kindledger.gateway.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransactionResponse {
    
    private String txHash;
    private String status;
    private BigDecimal amount;
    private String walletAddress;
    private String transactionType;
    private Long campaignId;
    private LocalDateTime createdAt;
    private String message;
    
    public TransactionResponse(String txHash, String status, String message) {
        this.txHash = txHash;
        this.status = status;
        this.message = message;
    }
}
