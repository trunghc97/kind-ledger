package com.mbbank.kindledger.gateway.repository;

import com.mbbank.kindledger.gateway.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByWalletAddress(String walletAddress);
    Optional<User> findByAccountNo(String accountNo);
    boolean existsByWalletAddress(String walletAddress);
    boolean existsByAccountNo(String accountNo);
}
