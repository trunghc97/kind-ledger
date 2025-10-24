package com.mbbank.kindledger.gateway.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "token_transactions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TokenTransaction {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "tx_hash", unique = true, nullable = false, length = 66)
    private String txHash;
    
    @Column(name = "wallet_address", nullable = false, length = 42)
    private String walletAddress;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 50)
    private TransactionType transactionType;
    
    @Column(name = "amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;
    
    @Column(name = "campaign_id")
    private Long campaignId;
    
    @Column(name = "block_number")
    private Long blockNumber;
    
    @Column(name = "gas_used")
    private Long gasUsed;
    
    @Column(name = "gas_price")
    private Long gasPrice;
    
    @Column(name = "status", length = 50)
    private String status = "PENDING";
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    public enum TransactionType {
        MINT, BURN, DONATE, BUY_ITEM, REDEEM
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
