package com.mbbank.kindledger.gateway.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "wallet_balances")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WalletBalance {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "wallet_address", unique = true, nullable = false, length = 42)
    private String walletAddress;
    
    @Column(name = "c_vnd_balance", precision = 18, scale = 2)
    private BigDecimal cVndBalance = BigDecimal.ZERO;
    
    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;
    
    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        lastUpdated = LocalDateTime.now();
    }
}
