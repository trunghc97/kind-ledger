package com.mbbank.kindledger.gateway.service;

import com.mbbank.kindledger.gateway.entity.TokenTransaction;
import com.mbbank.kindledger.gateway.entity.WalletBalance;
import com.mbbank.kindledger.gateway.repository.TokenTransactionRepository;
import com.mbbank.kindledger.gateway.repository.WalletBalanceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class TransactionService {
    
    private final TokenTransactionRepository tokenTransactionRepository;
    private final WalletBalanceRepository walletBalanceRepository;
    private final BlockchainService blockchainService;
    
    @Transactional
    public String mintTokens(String walletAddress, String accountNo, BigDecimal amount) {
        try {
            log.info("Processing mint request: {} cVND to {}", amount, walletAddress);
            
            // Simulate AML check
            if (!amlCheck(amount, true)) {
                throw new RuntimeException("AML check failed");
            }
            
            // Simulate Core Bank transfer
            if (!coreTransfer(accountNo, amount)) {
                throw new RuntimeException("Core Bank transfer failed");
            }
            
            // Execute blockchain mint
            String txHash = blockchainService.mintTokens(walletAddress, amount).get();
            
            // Create transaction record
            TokenTransaction transaction = new TokenTransaction();
            transaction.setTxHash(txHash);
            transaction.setWalletAddress(walletAddress);
            transaction.setTransactionType(TokenTransaction.TransactionType.MINT);
            transaction.setAmount(amount);
            transaction.setStatus("SUCCESS");
            tokenTransactionRepository.save(transaction);
            
            // Update wallet balance
            updateWalletBalance(walletAddress, amount);
            
            log.info("Mint completed successfully: {}", txHash);
            return txHash;
            
        } catch (Exception e) {
            log.error("Error minting tokens", e);
            throw new RuntimeException("Mint failed: " + e.getMessage());
        }
    }
    
    @Transactional
    public String burnTokens(String walletAddress, BigDecimal amount) {
        try {
            log.info("Processing burn request: {} cVND from {}", amount, walletAddress);
            
            // Check balance
            WalletBalance balance = walletBalanceRepository.findByWalletAddress(walletAddress)
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
            
            if (balance.getCVndBalance().compareTo(amount) < 0) {
                throw new RuntimeException("Insufficient balance");
            }
            
            // Execute blockchain burn
            String txHash = blockchainService.burnTokens(walletAddress, amount).get();
            
            // Create transaction record
            TokenTransaction transaction = new TokenTransaction();
            transaction.setTxHash(txHash);
            transaction.setWalletAddress(walletAddress);
            transaction.setTransactionType(TokenTransaction.TransactionType.BURN);
            transaction.setAmount(amount);
            transaction.setStatus("SUCCESS");
            tokenTransactionRepository.save(transaction);
            
            // Update wallet balance
            updateWalletBalance(walletAddress, amount.negate());
            
            log.info("Burn completed successfully: {}", txHash);
            return txHash;
            
        } catch (Exception e) {
            log.error("Error burning tokens", e);
            throw new RuntimeException("Burn failed: " + e.getMessage());
        }
    }
    
    public List<TokenTransaction> getWalletTransactions(String walletAddress) {
        return tokenTransactionRepository.findByWalletAddress(walletAddress);
    }
    
    public Optional<WalletBalance> getWalletBalance(String walletAddress) {
        return walletBalanceRepository.findByWalletAddress(walletAddress);
    }
    
    private void updateWalletBalance(String walletAddress, BigDecimal amount) {
        Optional<WalletBalance> balanceOpt = walletBalanceRepository.findByWalletAddress(walletAddress);
        if (balanceOpt.isPresent()) {
            WalletBalance balance = balanceOpt.get();
            balance.setCVndBalance(balance.getCVndBalance().add(amount));
            walletBalanceRepository.save(balance);
        } else {
            WalletBalance newBalance = new WalletBalance();
            newBalance.setWalletAddress(walletAddress);
            newBalance.setCVndBalance(amount);
            walletBalanceRepository.save(newBalance);
        }
    }
    
    // Simulate AML check
    private boolean amlCheck(BigDecimal amount, boolean kyc) {
        if (!kyc && amount.compareTo(BigDecimal.valueOf(10_000_000)) > 0) {
            log.warn("AML check failed: Anonymous transaction over 10M VND");
            return false;
        }
        log.info("AML check passed for amount: {}", amount);
        return true;
    }
    
    // Simulate Core Bank transfer
    private boolean coreTransfer(String accountNo, BigDecimal amount) {
        log.info("Simulate CoreBank transfer: {} - {}", accountNo, amount);
        // Always return true for simulation
        return true;
    }
}
