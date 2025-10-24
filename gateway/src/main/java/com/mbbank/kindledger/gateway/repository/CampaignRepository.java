package com.mbbank.kindledger.gateway.repository;

import com.mbbank.kindledger.gateway.entity.Campaign;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CampaignRepository extends JpaRepository<Campaign, Long> {
    List<Campaign> findByStatus(String status);
    
    @Query("SELECT c FROM Campaign c WHERE c.status = 'ACTIVE' ORDER BY c.createdAt DESC")
    List<Campaign> findActiveCampaigns();
    
    @Query("SELECT c FROM Campaign c WHERE c.creatorWallet = ?1")
    List<Campaign> findByCreatorWallet(String creatorWallet);
}
