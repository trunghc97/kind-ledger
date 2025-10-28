package com.kindledger.gateway.controller;

import com.kindledger.gateway.model.Campaign;
import com.kindledger.gateway.model.DonationRequest;
import com.kindledger.gateway.service.FabricService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class CampaignController {
    
    private static final Logger logger = LoggerFactory.getLogger(CampaignController.class);
    
    @Autowired
    private FabricService fabricService;
    
    @PostMapping("/campaigns")
    public ResponseEntity<Map<String, Object>> createCampaign(@RequestBody(required = false) Campaign campaign) {
        try {
            // Validate request body
            if (campaign == null) {
                return createErrorResponse("Campaign data is required");
            }
            
            logger.info("Creating campaign: {}", campaign.getName());
            
            // Validate campaign
            if (campaign.getName() == null || campaign.getName().trim().isEmpty()) {
                return createErrorResponse("Campaign name is required");
            }
            if (campaign.getId() == null || campaign.getId().trim().isEmpty()) {
                return createErrorResponse("Campaign ID is required");
            }
            if (campaign.getGoal() == null || campaign.getGoal() <= 0) {
                return createErrorResponse("Valid campaign goal is required");
            }
            
            // Use FabricService to create campaign on blockchain
            try {
                Campaign createdCampaign = fabricService.createCampaign(
                    campaign.getId(),
                    campaign.getName(),
                    campaign.getDescription() != null ? campaign.getDescription() : "",
                    campaign.getOwner() != null ? campaign.getOwner() : "",
                    campaign.getGoal()
                );
                
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Campaign created successfully on blockchain");
                response.put("data", createdCampaign);
                
                return ResponseEntity.ok(response);
            } catch (RuntimeException e) {
                logger.warn("Blockchain operation failed: {}", e.getMessage());
                // Return success even if blockchain fails (graceful degradation)
                // Ensure raised is initialized
                if (campaign.getRaised() == null) {
                    campaign.setRaised(0.0);
                }
                if (campaign.getStatus() == null) {
                    campaign.setStatus("OPEN");
                }
                
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Campaign data received but blockchain is not available");
                response.put("warning", "Blockchain operation failed: " + e.getMessage());
                response.put("data", campaign);
                
                return ResponseEntity.ok(response);
            }
            
        } catch (Exception e) {
            logger.error("Error creating campaign: {}", e.getMessage());
            return createErrorResponse("Failed to create campaign: " + e.getMessage());
        }
    }
    
    @PostMapping("/donate")
    public ResponseEntity<Map<String, Object>> donate(@RequestBody(required = false) DonationRequest donationRequest) {
        try {
            // Validate request body
            if (donationRequest == null) {
                return createErrorResponse("Donation data is required");
            }
            
            logger.info("Processing donation: {} to campaign {}", 
                donationRequest.getAmount(), donationRequest.getCampaignId());
            
            // Validate donation
            if (donationRequest.getCampaignId() == null || donationRequest.getCampaignId().trim().isEmpty()) {
                return createErrorResponse("Campaign ID is required");
            }
            if (donationRequest.getAmount() == null || donationRequest.getAmount() <= 0) {
                return createErrorResponse("Donation amount must be greater than 0");
            }
            
            // Use FabricService to process donation on blockchain
            try {
                Campaign updatedCampaign = fabricService.donate(
                    donationRequest.getCampaignId(),
                    donationRequest.getDonorId() != null ? donationRequest.getDonorId() : "anonymous",
                    donationRequest.getDonorName() != null ? donationRequest.getDonorName() : "Anonymous Donor",
                    donationRequest.getAmount()
                );
                
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Donation processed successfully on blockchain");
                response.put("data", donationRequest);
                response.put("campaign", updatedCampaign);
                
                return ResponseEntity.ok(response);
            } catch (RuntimeException e) {
                logger.warn("Blockchain operation failed: {}", e.getMessage());
                // Return success even if blockchain fails (graceful degradation)
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Donation data received but blockchain is not available");
                response.put("warning", "Blockchain operation failed: " + e.getMessage());
                response.put("data", donationRequest);
                
                return ResponseEntity.ok(response);
            }
            
        } catch (Exception e) {
            logger.error("Error processing donation: {}", e.getMessage());
            return createErrorResponse("Failed to process donation: " + e.getMessage());
        }
    }
    
    @GetMapping("/campaigns/{id}")
    public ResponseEntity<Map<String, Object>> getCampaign(@PathVariable String id) {
        try {
            logger.info("Getting campaign: {}", id);
            
            // Use FabricService to get campaign
            Campaign campaign = fabricService.queryCampaign(id);
            
            if (campaign == null) {
                return createErrorResponse("Campaign not found");
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Campaign retrieved successfully");
            response.put("data", campaign);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error getting campaign: {}", e.getMessage());
            return createErrorResponse("Failed to get campaign: " + e.getMessage());
        }
    }
    
    @GetMapping("/campaigns")
    public ResponseEntity<Map<String, Object>> getAllCampaigns() {
        try {
            logger.info("Getting all campaigns");
            
            // Use FabricService to get all campaigns
            List<Campaign> campaignsData = fabricService.queryAllCampaigns();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Campaigns retrieved successfully");
            response.put("data", campaignsData);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error getting all campaigns: {}", e.getMessage());
            return createErrorResponse("Failed to get campaigns: " + e.getMessage());
        }
    }
    
    @GetMapping("/stats/total")
    public ResponseEntity<Map<String, Object>> getTotalDonations() {
        try {
            logger.info("Getting total donations");
            
            // Use FabricService to get total donations
            Double totalDonations = fabricService.getTotalDonations();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Total donations retrieved successfully");
            response.put("data", totalDonations);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error getting total donations: {}", e.getMessage());
            return createErrorResponse("Failed to get total donations: " + e.getMessage());
        }
    }
    
    @PostMapping("/init")
    public ResponseEntity<Map<String, Object>> initLedger() {
        try {
            logger.info("Initializing ledger");
            
            // Use FabricService to initialize ledger
            fabricService.initLedger();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Ledger initialized successfully");
            response.put("data", "Initialized");
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error initializing ledger: {}", e.getMessage());
            return createErrorResponse("Failed to initialize ledger: " + e.getMessage());
        }
    }
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Kind-Ledger Gateway");
        response.put("timestamp", System.currentTimeMillis());
        
        return ResponseEntity.ok(response);
    }
    
    private ResponseEntity<Map<String, Object>> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", message);
        return ResponseEntity.badRequest().body(response);
    }
}
