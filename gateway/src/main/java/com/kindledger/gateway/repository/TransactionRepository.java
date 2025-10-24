package com.kindledger.gateway.repository;

import com.kindledger.gateway.entity.TransactionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<TransactionEntity, UUID> {
    
    Optional<TransactionEntity> findByTransactionId(String transactionId);
    
    List<TransactionEntity> findByCampaignId(String campaignId);
    
    List<TransactionEntity> findByDonorId(String donorId);
    
    List<TransactionEntity> findByType(TransactionEntity.TransactionType type);
    
    List<TransactionEntity> findByStatus(TransactionEntity.TransactionStatus status);
    
    List<TransactionEntity> findByCampaignIdAndType(String campaignId, TransactionEntity.TransactionType type);
    
    List<TransactionEntity> findByDonorIdAndType(String donorId, TransactionEntity.TransactionType type);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.campaignId = :campaignId ORDER BY t.createdAt DESC")
    List<TransactionEntity> findByCampaignIdOrderByCreatedAtDesc(@Param("campaignId") String campaignId);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.donorId = :donorId ORDER BY t.createdAt DESC")
    List<TransactionEntity> findByDonorIdOrderByCreatedAtDesc(@Param("donorId") String donorId);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.type = :type ORDER BY t.createdAt DESC")
    List<TransactionEntity> findByTypeOrderByCreatedAtDesc(@Param("type") TransactionEntity.TransactionType type);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.status = :status ORDER BY t.createdAt DESC")
    List<TransactionEntity> findByStatusOrderByCreatedAtDesc(@Param("status") TransactionEntity.TransactionStatus status);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.createdAt BETWEEN :startDate AND :endDate ORDER BY t.createdAt DESC")
    List<TransactionEntity> findByDateRange(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.blockNumber IS NOT NULL ORDER BY t.blockNumber DESC")
    List<TransactionEntity> findConfirmedTransactions();
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.blockNumber IS NULL ORDER BY t.createdAt DESC")
    List<TransactionEntity> findPendingTransactions();
    
    @Query("SELECT SUM(t.amount) FROM TransactionEntity t WHERE t.type = :type AND t.status = 'COMPLETED'")
    Optional<BigDecimal> getTotalAmountByType(@Param("type") TransactionEntity.TransactionType type);
    
    @Query("SELECT COUNT(t) FROM TransactionEntity t WHERE t.type = :type AND t.status = 'COMPLETED'")
    Long countByType(@Param("type") TransactionEntity.TransactionType type);
    
    @Query("SELECT COUNT(t) FROM TransactionEntity t WHERE t.status = :status")
    Long countByStatus(@Param("status") TransactionEntity.TransactionStatus status);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.campaignId = :campaignId AND t.type = 'DONATE' AND t.status = 'COMPLETED'")
    List<TransactionEntity> findDonationTransactionsByCampaign(@Param("campaignId") String campaignId);
    
    @Query("SELECT t FROM TransactionEntity t WHERE t.donorId = :donorId AND t.type = 'DONATE' AND t.status = 'COMPLETED'")
    List<TransactionEntity> findDonationTransactionsByDonor(@Param("donorId") String donorId);
    
    boolean existsByTransactionId(String transactionId);
}
