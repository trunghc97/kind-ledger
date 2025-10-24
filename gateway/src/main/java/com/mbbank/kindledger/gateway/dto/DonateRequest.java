package com.mbbank.kindledger.gateway.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DonateRequest {
    
    @NotNull(message = "Wallet address is required")
    private String walletAddress;
    
    @NotNull(message = "Campaign ID is required")
    private Long campaignId;
    
    @NotNull(message = "Amount is required")
    @Positive(message = "Amount must be positive")
    private BigDecimal amount;
    
    private String message;
}
