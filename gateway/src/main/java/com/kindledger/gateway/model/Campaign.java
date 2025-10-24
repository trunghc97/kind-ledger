package com.kindledger.gateway.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDateTime;
import java.util.List;

public class Campaign {
    
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("description")
    private String description;
    
    @JsonProperty("owner")
    private String owner;
    
    @JsonProperty("goal")
    private Double goal;
    
    @JsonProperty("raised")
    private Double raised;
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("createdAt")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;
    
    @JsonProperty("updatedAt")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;
    
    @JsonProperty("donors")
    private List<Donor> donors;
    
    // Constructors
    public Campaign() {}
    
    public Campaign(String id, String name, String description, String owner, Double goal) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.owner = owner;
        this.goal = goal;
        this.raised = 0.0;
        this.status = "OPEN";
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
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
    
    public Double getGoal() {
        return goal;
    }
    
    public void setGoal(Double goal) {
        this.goal = goal;
    }
    
    public Double getRaised() {
        return raised;
    }
    
    public void setRaised(Double raised) {
        this.raised = raised;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
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
    
    public List<Donor> getDonors() {
        return donors;
    }
    
    public void setDonors(List<Donor> donors) {
        this.donors = donors;
    }
    
    // Helper methods
    public Double getProgressPercentage() {
        if (goal == null || goal == 0) {
            return 0.0;
        }
        return (raised / goal) * 100;
    }
    
    public boolean isCompleted() {
        return "COMPLETED".equals(status);
    }
    
    public boolean isOpen() {
        return "OPEN".equals(status);
    }
}
