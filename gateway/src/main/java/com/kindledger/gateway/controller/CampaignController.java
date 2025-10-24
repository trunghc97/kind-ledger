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
    public ResponseEntity<Map<String, Object>> createCampaign(@RequestBody Campaign campaign) {
        try {
            logger.info("Creating campaign: {}", campaign.getName());
            
            Campaign createdCampaign = fabricService.createCampaign(
                campaign.getId(),
                campaign.getName(),
                campaign.getDescription(),
                campaign.getOwner(),
                campaign.getGoal()
            );
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Campaign created successfully");
            response.put("data", createdCampaign);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error creating campaign: {}", e.getMessage());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to create campaign: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @PostMapping("/donate")
    public ResponseEntity<Map<String, Object>> donate(@RequestBody DonationRequest donationRequest) {
        try {
            logger.info("Processing donation: {} to campaign {}", 
                donationRequest.getAmount(), donationRequest.getCampaignId());
            
            Campaign updatedCampaign = fabricService.donate(
                donationRequest.getCampaignId(),
                donationRequest.getDonorId(),
                donationRequest.getDonorName(),
                donationRequest.getAmount()
            );
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Donation processed successfully");
            response.put("data", updatedCampaign);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error processing donation: {}", e.getMessage());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to process donation: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @GetMapping("/campaigns/{id}")
    public ResponseEntity<Map<String, Object>> getCampaign(@PathVariable String id) {
        try {
            logger.info("Getting campaign: {}", id);
            
            Campaign campaign = fabricService.queryCampaign(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Campaign retrieved successfully");
            response.put("data", campaign);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error getting campaign: {}", e.getMessage());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to get campaign: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @GetMapping("/campaigns")
    public ResponseEntity<Map<String, Object>> getAllCampaigns() {
        try {
            logger.info("Getting all campaigns");
            
            List<Campaign> campaigns = fabricService.queryAllCampaigns();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Campaigns retrieved successfully");
            response.put("data", campaigns);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error getting all campaigns: {}", e.getMessage());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to get campaigns: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @GetMapping("/stats/total")
    public ResponseEntity<Map<String, Object>> getTotalDonations() {
        try {
            logger.info("Getting total donations");
            
            Double total = fabricService.getTotalDonations();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Total donations retrieved successfully");
            response.put("data", total);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error getting total donations: {}", e.getMessage());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to get total donations: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @PostMapping("/init")
    public ResponseEntity<Map<String, Object>> initLedger() {
        try {
            logger.info("Initializing ledger");
            
            fabricService.initLedger();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Ledger initialized successfully");
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error initializing ledger: {}", e.getMessage());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to initialize ledger: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
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
}
