package com.kindledger.gateway.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kindledger.gateway.config.FabricConfig;
import com.kindledger.gateway.model.Campaign;
import com.kindledger.gateway.model.DonationRequest;
import org.hyperledger.fabric.gateway.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.concurrent.TimeoutException;

@Service
public class FabricService {
    
    private static final Logger logger = LoggerFactory.getLogger(FabricService.class);
    
    @Autowired
    private FabricConfig fabricConfig;
    
    private Gateway gateway;
    private Network network;
    private Contract contract;
    
    @PostConstruct
    public void initialize() throws Exception {
        logger.info("Initializing Fabric connection...");
        
        // Load connection profile
        Path networkConfigPath = Paths.get(fabricConfig.getNetworkConfigPath());
        
        // Load wallet
        Path walletPath = Paths.get("wallet");
        Wallet wallet = Wallets.newFileSystemWallet(walletPath);
        
        // Load user identity
        if (!wallet.exists(fabricConfig.getUser())) {
            logger.error("User {} not found in wallet", fabricConfig.getUser());
            throw new Exception("User not found in wallet");
        }
        
        // Create gateway
        Gateway.Builder builder = Gateway.createBuilder()
                .identity(wallet, fabricConfig.getUser())
                .networkConfig(networkConfigPath)
                .discovery(true);
        
        gateway = builder.connect();
        network = gateway.getNetwork(fabricConfig.getChannelName());
        contract = network.getContract(fabricConfig.getChaincodeName());
        
        logger.info("Fabric connection initialized successfully");
    }
    
    public Campaign createCampaign(String id, String name, String description, String owner, Double goal) {
        try {
            logger.info("Creating campaign: {}", id);
            
            byte[] result = contract.submitTransaction(
                "CreateCampaign", 
                id, 
                name, 
                description, 
                owner, 
                goal.toString()
            );
            
            logger.info("Campaign created successfully: {}", new String(result));
            return queryCampaign(id);
            
        } catch (Exception e) {
            logger.error("Error creating campaign: {}", e.getMessage());
            throw new RuntimeException("Failed to create campaign", e);
        }
    }
    
    public Campaign donate(String campaignId, String donorId, String donorName, Double amount) {
        try {
            logger.info("Processing donation: {} to campaign {}", amount, campaignId);
            
            byte[] result = contract.submitTransaction(
                "Donate", 
                campaignId, 
                donorId, 
                donorName, 
                amount.toString()
            );
            
            logger.info("Donation processed successfully: {}", new String(result));
            return queryCampaign(campaignId);
            
        } catch (Exception e) {
            logger.error("Error processing donation: {}", e.getMessage());
            throw new RuntimeException("Failed to process donation", e);
        }
    }
    
    public Campaign queryCampaign(String campaignId) {
        try {
            logger.info("Querying campaign: {}", campaignId);
            
            byte[] result = contract.evaluateTransaction("QueryCampaign", campaignId);
            
            ObjectMapper mapper = new ObjectMapper();
            Campaign campaign = mapper.readValue(new String(result), Campaign.class);
            
            logger.info("Campaign queried successfully: {}", campaign.getName());
            return campaign;
            
        } catch (Exception e) {
            logger.error("Error querying campaign: {}", e.getMessage());
            throw new RuntimeException("Failed to query campaign", e);
        }
    }
    
    @SuppressWarnings("unchecked")
    public List<Campaign> queryAllCampaigns() {
        try {
            logger.info("Querying all campaigns");
            
            byte[] result = contract.evaluateTransaction("QueryAllCampaigns");
            
            ObjectMapper mapper = new ObjectMapper();
            List<Campaign> campaigns = mapper.readValue(new String(result), List.class);
            
            logger.info("All campaigns queried successfully: {} campaigns found", campaigns.size());
            return campaigns;
            
        } catch (Exception e) {
            logger.error("Error querying all campaigns: {}", e.getMessage());
            throw new RuntimeException("Failed to query all campaigns", e);
        }
    }
    
    public Double getTotalDonations() {
        try {
            logger.info("Getting total donations");
            
            byte[] result = contract.evaluateTransaction("GetTotalDonations");
            
            Double total = Double.parseDouble(new String(result));
            
            logger.info("Total donations: {}", total);
            return total;
            
        } catch (Exception e) {
            logger.error("Error getting total donations: {}", e.getMessage());
            throw new RuntimeException("Failed to get total donations", e);
        }
    }
    
    public void initLedger() {
        try {
            logger.info("Initializing ledger");
            
            byte[] result = contract.submitTransaction("InitLedger");
            
            logger.info("Ledger initialized successfully: {}", new String(result));
            
        } catch (Exception e) {
            logger.error("Error initializing ledger: {}", e.getMessage());
            throw new RuntimeException("Failed to initialize ledger", e);
        }
    }
    
    public void close() {
        if (gateway != null) {
            try {
                gateway.close();
                logger.info("Fabric connection closed");
            } catch (Exception e) {
                logger.error("Error closing Fabric connection: {}", e.getMessage());
            }
        }
    }
}
