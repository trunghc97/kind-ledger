package com.kindledger.gateway.repository;

import com.kindledger.gateway.entity.TokenTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TokenTransactionRepository extends JpaRepository<TokenTransaction, String> {
    Optional<TokenTransaction> findByTxRef(String txRef);
    Optional<TokenTransaction> findByTokenHash(String tokenHash);
}
