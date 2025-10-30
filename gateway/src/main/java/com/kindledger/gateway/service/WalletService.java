package com.kindledger.gateway.service;

import com.kindledger.gateway.entity.WalletEntity;
import com.kindledger.gateway.entity.WalletStatus;
import com.kindledger.gateway.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class WalletService {

    private final WalletRepository walletRepository;

    @Transactional
    public WalletEntity createPendingWalletForUser(UUID userId, String address) {
        WalletEntity wallet = new WalletEntity();
        wallet.setUserId(userId);
        wallet.setAddress(address);
        wallet.setBalance(BigDecimal.ZERO);
        wallet.setStatus(WalletStatus.PENDING);
        return walletRepository.save(wallet);
    }

    @Transactional
    public WalletEntity activateWallet(UUID userId) {
        WalletEntity wallet = walletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalStateException("Wallet not found for user"));
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            wallet.setStatus(WalletStatus.ACTIVE);
            wallet = walletRepository.save(wallet);
            log.info("Wallet {} activated for user {}", wallet.getId(), userId);
        }
        return wallet;
    }

    public WalletEntity getByUserId(UUID userId) {
        return walletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalStateException("Wallet not found for user"));
    }

    public WalletEntity getByAddress(String address) {
        return walletRepository.findByAddress(address)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found for address"));
    }
}
