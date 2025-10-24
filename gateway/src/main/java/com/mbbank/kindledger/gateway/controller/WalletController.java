package com.mbbank.kindledger.gateway.controller;

import com.mbbank.kindledger.gateway.entity.User;
import com.mbbank.kindledger.gateway.entity.WalletBalance;
import com.mbbank.kindledger.gateway.service.WalletService;
import com.mbbank.kindledger.gateway.service.TransactionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/wallet")
@Slf4j
public class WalletController {
    
    @Autowired
    private WalletService walletService;
    
    @Autowired
    private TransactionService transactionService;
    
    /**
     * Tạo ví mới cho người dùng
     * POST /api/wallet/create
     * Body: {"accountNo": "1234567890"}
     */
    @PostMapping("/create")
    public ResponseEntity<Map<String, Object>> createWallet(@RequestBody Map<String, String> request) {
        try {
            String accountNo = request.get("accountNo");
            if (accountNo == null || accountNo.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Account number is required"));
            }
            
            // Kiểm tra xem đã có ví cho account này chưa
            Optional<String> existingWallet = walletService.getWalletByAccountNo(accountNo);
            if (existingWallet.isPresent()) {
                Map<String, Object> response = new HashMap<>();
                response.put("message", "Wallet already exists for this account");
                response.put("walletAddress", existingWallet.get());
                response.put("accountNo", accountNo);
                return ResponseEntity.ok(response);
            }
            
            // Tạo ví mới
            String walletAddress = walletService.createWalletForUser(accountNo);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Wallet created successfully");
            response.put("walletAddress", walletAddress);
            response.put("accountNo", accountNo);
            
            log.info("Created new wallet {} for account {}", walletAddress, accountNo);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error creating wallet", e);
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to create wallet: " + e.getMessage()));
        }
    }
    
    /**
     * Lấy thông tin ví theo số tài khoản
     * GET /api/wallet/account/{accountNo}
     */
    @GetMapping("/account/{accountNo}")
    public ResponseEntity<Map<String, Object>> getWalletByAccount(@PathVariable String accountNo) {
        try {
            Optional<String> walletAddress = walletService.getWalletByAccountNo(accountNo);
            
            if (walletAddress.isPresent()) {
                // Lấy thông tin user
                Optional<User> user = walletService.getUserByWalletAddress(walletAddress.get());
                
                // Lấy số dư ví
                Optional<WalletBalance> balance = transactionService.getWalletBalance(walletAddress.get());
                
                Map<String, Object> response = new HashMap<>();
                response.put("accountNo", accountNo);
                response.put("walletAddress", walletAddress.get());
                response.put("kycStatus", user.map(User::getKycStatus).orElse(false));
                response.put("kycLevel", user.map(User::getKycLevel).orElse(0));
                response.put("balance", balance.map(WalletBalance::getCVndBalance).orElse(java.math.BigDecimal.ZERO));
                
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.notFound().build();
            }
            
        } catch (Exception e) {
            log.error("Error getting wallet for account: {}", accountNo, e);
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to get wallet: " + e.getMessage()));
        }
    }
    
    /**
     * Lấy thông tin ví theo địa chỉ ví
     * GET /api/wallet/{walletAddress}
     */
    @GetMapping("/{walletAddress}")
    public ResponseEntity<Map<String, Object>> getWalletInfo(@PathVariable String walletAddress) {
        try {
            Optional<User> user = walletService.getUserByWalletAddress(walletAddress);
            
            if (user.isPresent()) {
                // Lấy số dư ví
                Optional<WalletBalance> balance = transactionService.getWalletBalance(walletAddress);
                
                Map<String, Object> response = new HashMap<>();
                response.put("walletAddress", walletAddress);
                response.put("accountNo", user.get().getAccountNo());
                response.put("kycStatus", user.get().getKycStatus());
                response.put("kycLevel", user.get().getKycLevel());
                response.put("balance", balance.map(WalletBalance::getCVndBalance).orElse(java.math.BigDecimal.ZERO));
                response.put("createdAt", user.get().getCreatedAt());
                
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.notFound().build();
            }
            
        } catch (Exception e) {
            log.error("Error getting wallet info: {}", walletAddress, e);
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to get wallet info: " + e.getMessage()));
        }
    }
    
    /**
     * Cập nhật trạng thái KYC
     * PUT /api/wallet/{walletAddress}/kyc
     * Body: {"kycStatus": true, "kycLevel": 1}
     */
    @PutMapping("/{walletAddress}/kyc")
    public ResponseEntity<Map<String, Object>> updateKycStatus(
            @PathVariable String walletAddress,
            @RequestBody Map<String, Object> request) {
        try {
            Boolean kycStatus = (Boolean) request.get("kycStatus");
            Integer kycLevel = (Integer) request.get("kycLevel");
            
            if (kycStatus == null || kycLevel == null) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "kycStatus and kycLevel are required"));
            }
            
            walletService.updateKycStatus(walletAddress, kycStatus, kycLevel);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "KYC status updated successfully");
            response.put("walletAddress", walletAddress);
            response.put("kycStatus", kycStatus);
            response.put("kycLevel", kycLevel);
            
            log.info("Updated KYC status for wallet {}: status={}, level={}", 
                walletAddress, kycStatus, kycLevel);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error updating KYC status for wallet: {}", walletAddress, e);
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to update KYC status: " + e.getMessage()));
        }
    }
    
    /**
     * Kiểm tra ví có tồn tại không
     * GET /api/wallet/{walletAddress}/exists
     */
    @GetMapping("/{walletAddress}/exists")
    public ResponseEntity<Map<String, Object>> checkWalletExists(@PathVariable String walletAddress) {
        try {
            boolean exists = walletService.walletExists(walletAddress);
            
            Map<String, Object> response = new HashMap<>();
            response.put("walletAddress", walletAddress);
            response.put("exists", exists);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error checking wallet existence: {}", walletAddress, e);
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to check wallet existence: " + e.getMessage()));
        }
    }
}
