package com.mbbank.kindledger.gateway.controller;

import com.mbbank.kindledger.gateway.dto.MintRequest;
import com.mbbank.kindledger.gateway.dto.TransactionResponse;
import com.mbbank.kindledger.gateway.entity.TokenTransaction;
import com.mbbank.kindledger.gateway.entity.WalletBalance;
import com.mbbank.kindledger.gateway.service.TransactionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class TransactionController {
    
    private final TransactionService transactionService;
    
    @PostMapping("/mint")
    public ResponseEntity<TransactionResponse> mintTokens(@Valid @RequestBody MintRequest request) {
        try {
            log.info("Mint request received: {}", request);
            String txHash = transactionService.mintTokens(
                request.getWalletAddress(), 
                request.getAccountNo(), 
                request.getAmount()
            );
            
            TransactionResponse response = new TransactionResponse(
                txHash, 
                "SUCCESS", 
                "Tokens minted successfully"
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error processing mint request", e);
            return ResponseEntity.badRequest()
                .body(new TransactionResponse(null, "FAILED", e.getMessage()));
        }
    }
    
    @PostMapping("/burn")
    public ResponseEntity<TransactionResponse> burnTokens(
            @RequestParam String walletAddress,
            @RequestParam BigDecimal amount) {
        try {
            log.info("Burn request received: {} - {}", walletAddress, amount);
            String txHash = transactionService.burnTokens(walletAddress, amount);
            
            TransactionResponse response = new TransactionResponse(
                txHash, 
                "SUCCESS", 
                "Tokens burned successfully"
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error processing burn request", e);
            return ResponseEntity.badRequest()
                .body(new TransactionResponse(null, "FAILED", e.getMessage()));
        }
    }
    
    @PostMapping("/redeem")
    public ResponseEntity<TransactionResponse> redeemTokens(
            @RequestParam String walletAddress,
            @RequestParam BigDecimal amount) {
        try {
            log.info("Redeem request received: {} - {}", walletAddress, amount);
            // Redeem is essentially the same as burn
            String txHash = transactionService.burnTokens(walletAddress, amount);
            
            TransactionResponse response = new TransactionResponse(
                txHash, 
                "SUCCESS", 
                "Tokens redeemed successfully"
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error processing redeem request", e);
            return ResponseEntity.badRequest()
                .body(new TransactionResponse(null, "FAILED", e.getMessage()));
        }
    }
    
    @GetMapping("/wallet/{walletAddress}/balance")
    public ResponseEntity<WalletBalance> getWalletBalance(@PathVariable String walletAddress) {
        try {
            return transactionService.getWalletBalance(walletAddress)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            log.error("Error getting wallet balance", e);
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping("/wallet/{walletAddress}/transactions")
    public ResponseEntity<List<TokenTransaction>> getWalletTransactions(@PathVariable String walletAddress) {
        try {
            List<TokenTransaction> transactions = transactionService.getWalletTransactions(walletAddress);
            return ResponseEntity.ok(transactions);
        } catch (Exception e) {
            log.error("Error getting wallet transactions", e);
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PostMapping("/kyc/check")
    public ResponseEntity<String> checkKyc(@RequestParam String walletAddress) {
        try {
            // Simulate KYC check
            log.info("KYC check for wallet: {}", walletAddress);
            return ResponseEntity.ok("KYC_VERIFIED");
        } catch (Exception e) {
            log.error("Error checking KYC", e);
            return ResponseEntity.badRequest().body("KYC_FAILED");
        }
    }
}
