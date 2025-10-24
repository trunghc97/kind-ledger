package com.kindledger.gateway.repository;

import com.kindledger.gateway.entity.CampaignEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface CampaignRepository extends JpaRepository<CampaignEntity, String> {
    
    List<CampaignEntity> findByStatus(CampaignEntity.CampaignStatus status);
    
    List<CampaignEntity> findByOwner(String owner);
    
    List<CampaignEntity> findByStatusAndOwner(CampaignEntity.CampaignStatus status, String owner);
    
    @Query("SELECT c FROM CampaignEntity c WHERE c.name LIKE %:keyword% OR c.description LIKE %:keyword%")
    List<CampaignEntity> findByKeyword(@Param("keyword") String keyword);
    
    @Query("SELECT c FROM CampaignEntity c WHERE c.raised >= c.goal")
    List<CampaignEntity> findCompletedCampaigns();
    
    @Query("SELECT c FROM CampaignEntity c WHERE c.raised < c.goal AND c.status = 'OPEN'")
    List<CampaignEntity> findActiveCampaigns();
    
    @Query("SELECT SUM(c.raised) FROM CampaignEntity c WHERE c.status = 'COMPLETED'")
    Optional<BigDecimal> getTotalRaisedAmount();
    
    @Query("SELECT COUNT(c) FROM CampaignEntity c WHERE c.status = 'COMPLETED'")
    Long countCompletedCampaigns();
    
    @Query("SELECT COUNT(c) FROM CampaignEntity c WHERE c.status = 'OPEN'")
    Long countActiveCampaigns();
    
    @Query(value = "SELECT * FROM campaign_stats WHERE status = :status ORDER BY created_at DESC", nativeQuery = true)
    List<Object[]> getCampaignStats(@Param("status") String status);
}
