package com.mbbank.kindledger.gateway.controller;

import com.mbbank.kindledger.gateway.dto.DonateRequest;
import com.mbbank.kindledger.gateway.dto.TransactionResponse;
import com.mbbank.kindledger.gateway.entity.Campaign;
import com.mbbank.kindledger.gateway.service.CampaignService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class CampaignController {
    
    private final CampaignService campaignService;
    
    @GetMapping("/campaigns")
    public ResponseEntity<List<Campaign>> getAllCampaigns() {
        try {
            List<Campaign> campaigns = campaignService.getAllCampaigns();
            return ResponseEntity.ok(campaigns);
        } catch (Exception e) {
            log.error("Error getting campaigns", e);
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping("/campaigns/active")
    public ResponseEntity<List<Campaign>> getActiveCampaigns() {
        try {
            List<Campaign> campaigns = campaignService.getActiveCampaigns();
            return ResponseEntity.ok(campaigns);
        } catch (Exception e) {
            log.error("Error getting active campaigns", e);
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping("/campaigns/{id}")
    public ResponseEntity<Campaign> getCampaignById(@PathVariable Long id) {
        try {
            Optional<Campaign> campaign = campaignService.getCampaignById(id);
            return campaign.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            log.error("Error getting campaign by id", e);
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PostMapping("/donate")
    public ResponseEntity<TransactionResponse> donate(@Valid @RequestBody DonateRequest request) {
        try {
            log.info("Donate request received: {}", request);
            String txHash = campaignService.donateToCampaign(
                request.getWalletAddress(),
                request.getCampaignId(),
                request.getAmount()
            );
            
            TransactionResponse response = new TransactionResponse(
                txHash, 
                "SUCCESS", 
                "Donation successful"
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error processing donation", e);
            return ResponseEntity.badRequest()
                .body(new TransactionResponse(null, "FAILED", e.getMessage()));
        }
    }
    
    @GetMapping("/campaigns/{id}/progress")
    public ResponseEntity<BigDecimal> getCampaignProgress(@PathVariable Long id) {
        try {
            BigDecimal progress = campaignService.getCampaignProgress(id);
            return ResponseEntity.ok(progress);
        } catch (Exception e) {
            log.error("Error getting campaign progress", e);
            return ResponseEntity.badRequest().build();
        }
    }
}
