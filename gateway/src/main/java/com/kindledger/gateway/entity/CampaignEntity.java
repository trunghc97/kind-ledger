package com.kindledger.gateway.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "campaigns")
public class CampaignEntity {
    
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "id", columnDefinition = "uuid")
    private String id;
    
    @Column(name = "name", nullable = false, length = 500)
    private String name;
    
    @Column(name = "description", columnDefinition = "TEXT")
    private String description;
    
    @Column(name = "owner", nullable = false)
    private String owner;
    
    @Column(name = "goal", nullable = false, precision = 15, scale = 2)
    private BigDecimal goal;
    
    @Column(name = "raised", nullable = false, precision = 15, scale = 2)
    private BigDecimal raised = BigDecimal.ZERO;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private CampaignStatus status = CampaignStatus.OPEN;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "completed_at")
    private LocalDateTime completedAt;
    
    @Column(name = "metadata", columnDefinition = "jsonb")
    private String metadata;
    
    @OneToMany(mappedBy = "campaignId", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DonationEntity> donations;
    
    // Constructors
    public CampaignEntity() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
    
    public CampaignEntity(String id, String name, String description, String owner, BigDecimal goal) {
        this();
        this.id = id;
        this.name = name;
        this.description = description;
        this.owner = owner;
        this.goal = goal;
    }
    
    // Getters and Setters
    public String getId() {
        return id;
    }
    
    public void setId(String id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getOwner() {
        return owner;
    }
    
    public void setOwner(String owner) {
        this.owner = owner;
    }
    
    public BigDecimal getGoal() {
        return goal;
    }
    
    public void setGoal(BigDecimal goal) {
        this.goal = goal;
    }
    
    public BigDecimal getRaised() {
        return raised;
    }
    
    public void setRaised(BigDecimal raised) {
        this.raised = raised;
    }
    
    public CampaignStatus getStatus() {
        return status;
    }
    
    public void setStatus(CampaignStatus status) {
        this.status = status;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public LocalDateTime getCompletedAt() {
        return completedAt;
    }
    
    public void setCompletedAt(LocalDateTime completedAt) {
        this.completedAt = completedAt;
    }
    
    public String getMetadata() {
        return metadata;
    }
    
    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
    
    public List<DonationEntity> getDonations() {
        return donations;
    }
    
    public void setDonations(List<DonationEntity> donations) {
        this.donations = donations;
    }
    
    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
    
    public enum CampaignStatus {
        OPEN, COMPLETED, CANCELLED, EXPIRED
    }
}
