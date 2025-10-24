package com.kindledger.gateway.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDateTime;

public class DonationRequest {
    
    @JsonProperty("campaignId")
    private String campaignId;
    
    @JsonProperty("donorId")
    private String donorId;
    
    @JsonProperty("donorName")
    private String donorName;
    
    @JsonProperty("amount")
    private Double amount;
    
    @JsonProperty("donatedAt")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime donatedAt;
    
    // Constructors
    public DonationRequest() {}
    
    public DonationRequest(String campaignId, String donorId, String donorName, Double amount) {
        this.campaignId = campaignId;
        this.donorId = donorId;
        this.donorName = donorName;
        this.amount = amount;
        this.donatedAt = LocalDateTime.now();
    }
    
    // Getters and Setters
    public String getCampaignId() {
        return campaignId;
    }
    
    public void setCampaignId(String campaignId) {
        this.campaignId = campaignId;
    }
    
    public String getDonorId() {
        return donorId;
    }
    
    public void setDonorId(String donorId) {
        this.donorId = donorId;
    }
    
    public String getDonorName() {
        return donorName;
    }
    
    public void setDonorName(String donorName) {
        this.donorName = donorName;
    }
    
    public Double getAmount() {
        return amount;
    }
    
    public void setAmount(Double amount) {
        this.amount = amount;
    }
    
    public LocalDateTime getDonatedAt() {
        return donatedAt;
    }
    
    public void setDonatedAt(LocalDateTime donatedAt) {
        this.donatedAt = donatedAt;
    }
}
