package com.kindledger.gateway.repository;

import com.kindledger.gateway.entity.WalletEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface WalletRepository extends JpaRepository<WalletEntity, UUID> {
    Optional<WalletEntity> findByUserId(UUID userId);
    Optional<WalletEntity> findByAddress(String address);
}
