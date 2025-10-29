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
import java.util.ArrayList;
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
        Path walletPath = Paths.get("/opt/gopath/src/github.com/hyperledger/fabric/peer/wallet");
        logger.info("Wallet path: {}", walletPath);
        logger.info("Wallet exists: {}", walletPath.toFile().exists());
        logger.info("Wallet contents: {}", java.util.Arrays.toString(walletPath.toFile().list()));
        
        Wallet wallet = Wallets.newFileSystemWallet(walletPath);
        
        // Check if user exists
        logger.info("Looking for user: {}", fabricConfig.getUser());
        logger.info("Available users in wallet: {}", wallet.list());
        
        Identity userIdentity = wallet.get(fabricConfig.getUser());
        if (userIdentity == null) {
            logger.error("User {} not found in wallet", fabricConfig.getUser());
            logger.error("Please ensure wallet identity file exists: {}/{}.id", walletPath, fabricConfig.getUser());
            throw new Exception("User not found in wallet");
        }
        
        logger.info("User identity found: {}", fabricConfig.getUser());
        
        // Create gateway without discovery to avoid peer configuration issues
        Gateway.Builder builder = Gateway.createBuilder()
                .identity(wallet, fabricConfig.getUser())
                .networkConfig(networkConfigPath)
                .discovery(false);

        try {
            gateway = builder.connect();
            network = gateway.getNetwork(fabricConfig.getChannelName());
        } catch (GatewayRuntimeException ex) {
            // Xử lý trường hợp SDK báo channel đã tồn tại trong client cache
            if (ex.getMessage() != null && ex.getMessage().contains("Channel by the name") && ex.getMessage().contains("already exists")) {
                logger.warn("Channel already exists in client cache, retrying with a fresh Gateway instance");
                try { if (gateway != null) gateway.close(); } catch (Exception ignore) {}
                gateway = builder.connect();
                network = gateway.getNetwork(fabricConfig.getChannelName());
            } else {
                throw ex;
            }
        }

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
            
            if (contract == null) {
                logger.warn("Contract is not initialized, returning null");
                return null;
            }
            
            byte[] result = contract.evaluateTransaction("QueryCampaign", campaignId);
            
            ObjectMapper mapper = new ObjectMapper();
            Campaign campaign = mapper.readValue(new String(result), Campaign.class);
            
            logger.info("Campaign queried successfully: {}", campaign.getName());
            return campaign;
            
        } catch (Exception e) {
            logger.error("Error querying campaign: {}", e.getMessage());
            logger.warn("Returning null due to blockchain connection issue");
            return null;
        }
    }
    
    @SuppressWarnings("unchecked")
    public List<Campaign> queryAllCampaigns() {
        try {
            logger.info("Querying all campaigns");
            
            if (contract == null) {
                logger.warn("Contract is not initialized, returning empty list");
                return new ArrayList<>();
            }
            
            byte[] result = contract.evaluateTransaction("QueryAllCampaigns");
            
            ObjectMapper mapper = new ObjectMapper();
            List<Campaign> campaigns = mapper.readValue(new String(result), List.class);
            
            logger.info("All campaigns queried successfully: {} campaigns found", campaigns.size());
            return campaigns;
            
        } catch (Exception e) {
            logger.error("Error querying all campaigns: {}", e.getMessage());
            logger.warn("Returning empty list due to blockchain connection issue");
            return new ArrayList<>();
        }
    }
    
    public Double getTotalDonations() {
        try {
            logger.info("Getting total donations");
            
            if (contract == null) {
                logger.warn("Contract is not initialized, returning 0.0");
                return 0.0;
            }
            
            byte[] result = contract.evaluateTransaction("GetTotalDonations");
            
            Double total = Double.parseDouble(new String(result));
            
            logger.info("Total donations: {}", total);
            return total;
            
        } catch (Exception e) {
            logger.error("Error getting total donations: {}", e.getMessage());
            logger.warn("Returning 0.0 due to blockchain connection issue");
            return 0.0;
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
