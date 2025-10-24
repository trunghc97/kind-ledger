package com.mbbank.kindledger.gateway.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "campaigns")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Campaign {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    @Column(name = "description", columnDefinition = "TEXT")
    private String description;
    
    @Column(name = "target_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal targetAmount;
    
    @Column(name = "raised_amount", precision = 18, scale = 2)
    private BigDecimal raisedAmount = BigDecimal.ZERO;
    
    @Column(name = "status", length = 50)
    private String status = "ACTIVE";
    
    @Column(name = "deadline")
    private LocalDateTime deadline;
    
    @Column(name = "evidence_hash", length = 255)
    private String evidenceHash;
    
    @Column(name = "creator_wallet", nullable = false, length = 42)
    private String creatorWallet;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
