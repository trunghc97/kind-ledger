package com.mbbank.kindledger.gateway.repository;

import com.mbbank.kindledger.gateway.entity.WalletBalance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface WalletBalanceRepository extends JpaRepository<WalletBalance, Long> {
    Optional<WalletBalance> findByWalletAddress(String walletAddress);
    boolean existsByWalletAddress(String walletAddress);
}
