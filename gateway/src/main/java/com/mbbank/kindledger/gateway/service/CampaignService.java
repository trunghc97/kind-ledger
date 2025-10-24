package com.mbbank.kindledger.gateway.service;

import com.mbbank.kindledger.gateway.entity.Campaign;
import com.mbbank.kindledger.gateway.entity.TokenTransaction;
import com.mbbank.kindledger.gateway.entity.WalletBalance;
import com.mbbank.kindledger.gateway.repository.CampaignRepository;
import com.mbbank.kindledger.gateway.repository.TokenTransactionRepository;
import com.mbbank.kindledger.gateway.repository.WalletBalanceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class CampaignService {
    
    private final CampaignRepository campaignRepository;
    private final TokenTransactionRepository tokenTransactionRepository;
    private final WalletBalanceRepository walletBalanceRepository;
    private final BlockchainService blockchainService;
    
    public List<Campaign> getAllCampaigns() {
        return campaignRepository.findAll();
    }
    
    public List<Campaign> getActiveCampaigns() {
        return campaignRepository.findActiveCampaigns();
    }
    
    public Optional<Campaign> getCampaignById(Long id) {
        return campaignRepository.findById(id);
    }
    
    @Transactional
    public String donateToCampaign(String walletAddress, Long campaignId, BigDecimal amount) {
        try {
            // Validate campaign exists
            Campaign campaign = campaignRepository.findById(campaignId)
                .orElseThrow(() -> new RuntimeException("Campaign not found"));
            
            // Check wallet balance
            WalletBalance balance = walletBalanceRepository.findByWalletAddress(walletAddress)
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
            
            if (balance.getCVndBalance().compareTo(amount) < 0) {
                throw new RuntimeException("Insufficient balance");
            }
            
            // Create transaction record
            TokenTransaction transaction = new TokenTransaction();
            transaction.setWalletAddress(walletAddress);
            transaction.setTransactionType(TokenTransaction.TransactionType.DONATE);
            transaction.setAmount(amount);
            transaction.setCampaignId(campaignId);
            transaction.setStatus("PENDING");
            
            // Execute blockchain transaction
            String txHash = blockchainService.transferTokens(walletAddress, campaign.getCreatorWallet(), amount).get();
            transaction.setTxHash(txHash);
            transaction.setStatus("SUCCESS");
            
            // Save transaction
            tokenTransactionRepository.save(transaction);
            
            // Update campaign raised amount
            campaign.setRaisedAmount(campaign.getRaisedAmount().add(amount));
            campaignRepository.save(campaign);
            
            // Update wallet balance
            balance.setCVndBalance(balance.getCVndBalance().subtract(amount));
            walletBalanceRepository.save(balance);
            
            log.info("Donation successful: {} cVND to campaign {}", amount, campaignId);
            return txHash;
            
        } catch (Exception e) {
            log.error("Error processing donation", e);
            throw new RuntimeException("Donation failed: " + e.getMessage());
        }
    }
    
    public BigDecimal getCampaignProgress(Long campaignId) {
        Optional<Campaign> campaign = campaignRepository.findById(campaignId);
        if (campaign.isPresent()) {
            BigDecimal totalRaised = tokenTransactionRepository.getTotalDonatedByCampaign(campaignId);
            if (totalRaised == null) totalRaised = BigDecimal.ZERO;
            return totalRaised;
        }
        return BigDecimal.ZERO;
    }
}
