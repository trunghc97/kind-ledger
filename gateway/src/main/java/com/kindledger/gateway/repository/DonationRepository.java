package com.kindledger.gateway.repository;

import com.kindledger.gateway.entity.DonationEntity;
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
public interface DonationRepository extends JpaRepository<DonationEntity, UUID> {
    
    List<DonationEntity> findByCampaignId(String campaignId);
    
    List<DonationEntity> findByDonorId(String donorId);
    
    List<DonationEntity> findByStatus(DonationEntity.DonationStatus status);
    
    List<DonationEntity> findByCampaignIdAndStatus(String campaignId, DonationEntity.DonationStatus status);
    
    @Query("SELECT d FROM DonationEntity d WHERE d.campaignId = :campaignId ORDER BY d.createdAt DESC")
    List<DonationEntity> findByCampaignIdOrderByCreatedAtDesc(@Param("campaignId") String campaignId);
    
    @Query("SELECT d FROM DonationEntity d WHERE d.donorId = :donorId ORDER BY d.createdAt DESC")
    List<DonationEntity> findByDonorIdOrderByCreatedAtDesc(@Param("donorId") String donorId);
    
    @Query("SELECT SUM(d.amount) FROM DonationEntity d WHERE d.campaignId = :campaignId AND d.status = 'COMPLETED'")
    Optional<BigDecimal> getTotalDonationsByCampaign(@Param("campaignId") String campaignId);
    
    @Query("SELECT SUM(d.amount) FROM DonationEntity d WHERE d.donorId = :donorId AND d.status = 'COMPLETED'")
    Optional<BigDecimal> getTotalDonationsByDonor(@Param("donorId") String donorId);
    
    @Query("SELECT COUNT(d) FROM DonationEntity d WHERE d.campaignId = :campaignId AND d.status = 'COMPLETED'")
    Long countDonationsByCampaign(@Param("campaignId") String campaignId);
    
    @Query("SELECT COUNT(d) FROM DonationEntity d WHERE d.donorId = :donorId AND d.status = 'COMPLETED'")
    Long countDonationsByDonor(@Param("donorId") String donorId);
    
    @Query("SELECT d FROM DonationEntity d WHERE d.createdAt BETWEEN :startDate AND :endDate ORDER BY d.createdAt DESC")
    List<DonationEntity> findByDateRange(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT SUM(d.amount) FROM DonationEntity d WHERE d.status = 'COMPLETED'")
    Optional<BigDecimal> getTotalDonationsAmount();
    
    @Query("SELECT COUNT(d) FROM DonationEntity d WHERE d.status = 'COMPLETED'")
    Long countTotalDonations();
    
    @Query(value = "SELECT * FROM donation_summary ORDER BY donation_date DESC LIMIT :limit", nativeQuery = true)
    List<Object[]> getDonationSummary(@Param("limit") int limit);
}
