package com.mbbank.kindledger.gateway.repository;

import com.mbbank.kindledger.gateway.entity.TokenTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface TokenTransactionRepository extends JpaRepository<TokenTransaction, Long> {
    Optional<TokenTransaction> findByTxHash(String txHash);
    
    List<TokenTransaction> findByWalletAddress(String walletAddress);
    
    List<TokenTransaction> findByCampaignId(Long campaignId);
    
    @Query("SELECT t FROM TokenTransaction t WHERE t.walletAddress = ?1 AND t.transactionType = ?2")
    List<TokenTransaction> findByWalletAddressAndTransactionType(String walletAddress, TokenTransaction.TransactionType transactionType);
    
    @Query("SELECT SUM(t.amount) FROM TokenTransaction t WHERE t.campaignId = ?1 AND t.transactionType = 'DONATE'")
    java.math.BigDecimal getTotalDonatedByCampaign(Long campaignId);
}
