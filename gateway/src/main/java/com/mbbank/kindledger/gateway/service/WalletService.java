package com.mbbank.kindledger.gateway.service;

import com.mbbank.kindledger.gateway.entity.User;
import com.mbbank.kindledger.gateway.entity.WalletBalance;
import com.mbbank.kindledger.gateway.repository.UserRepository;
import com.mbbank.kindledger.gateway.repository.WalletBalanceRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.Keys;

import java.math.BigDecimal;
import java.util.Optional;

@Service
@Slf4j
public class WalletService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private WalletBalanceRepository walletBalanceRepository;
    
    /**
     * Tạo ví mới cho người dùng
     * @param accountNo Số tài khoản ngân hàng
     * @return Địa chỉ ví được tạo
     */
    @Transactional
    public String createWalletForUser(String accountNo) {
        try {
            log.info("Creating new wallet for account: {}", accountNo);
            
            // Tạo key pair mới
            Credentials credentials = Credentials.create(Keys.createEcKeyPair());
            String walletAddress = credentials.getAddress();
            
            log.info("Generated wallet address: {}", walletAddress);
            
            // Tạo user mới với ví
            User user = new User();
            user.setWalletAddress(walletAddress);
            user.setAccountNo(accountNo);
            user.setKycStatus(false);
            user.setKycLevel(0);
            
            userRepository.save(user);
            
            // Tạo wallet balance mới
            WalletBalance walletBalance = new WalletBalance();
            walletBalance.setWalletAddress(walletAddress);
            walletBalance.setCVndBalance(BigDecimal.ZERO);
            
            walletBalanceRepository.save(walletBalance);
            
            log.info("Successfully created wallet {} for account {}", walletAddress, accountNo);
            return walletAddress;
            
        } catch (Exception e) {
            log.error("Error creating wallet for account: {}", accountNo, e);
            throw new RuntimeException("Failed to create wallet", e);
        }
    }
    
    /**
     * Lấy thông tin ví của người dùng theo số tài khoản
     * @param accountNo Số tài khoản ngân hàng
     * @return Địa chỉ ví nếu tồn tại
     */
    public Optional<String> getWalletByAccountNo(String accountNo) {
        try {
            Optional<User> user = userRepository.findByAccountNo(accountNo);
            return user.map(User::getWalletAddress);
        } catch (Exception e) {
            log.error("Error getting wallet for account: {}", accountNo, e);
            return Optional.empty();
        }
    }
    
    /**
     * Lấy thông tin ví của người dùng theo địa chỉ ví
     * @param walletAddress Địa chỉ ví
     * @return Thông tin user nếu tồn tại
     */
    public Optional<User> getUserByWalletAddress(String walletAddress) {
        try {
            return userRepository.findByWalletAddress(walletAddress);
        } catch (Exception e) {
            log.error("Error getting user for wallet: {}", walletAddress, e);
            return Optional.empty();
        }
    }
    
    /**
     * Kiểm tra ví có tồn tại không
     * @param walletAddress Địa chỉ ví
     * @return true nếu ví tồn tại
     */
    public boolean walletExists(String walletAddress) {
        try {
            return userRepository.existsByWalletAddress(walletAddress);
        } catch (Exception e) {
            log.error("Error checking wallet existence: {}", walletAddress, e);
            return false;
        }
    }
    
    /**
     * Cập nhật trạng thái KYC cho ví
     * @param walletAddress Địa chỉ ví
     * @param kycStatus Trạng thái KYC
     * @param kycLevel Mức độ KYC
     */
    @Transactional
    public void updateKycStatus(String walletAddress, boolean kycStatus, int kycLevel) {
        try {
            Optional<User> userOpt = userRepository.findByWalletAddress(walletAddress);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                user.setKycStatus(kycStatus);
                user.setKycLevel(kycLevel);
                userRepository.save(user);
                
                log.info("Updated KYC status for wallet {}: status={}, level={}", 
                    walletAddress, kycStatus, kycLevel);
            } else {
                log.warn("Wallet not found for KYC update: {}", walletAddress);
            }
        } catch (Exception e) {
            log.error("Error updating KYC status for wallet: {}", walletAddress, e);
            throw new RuntimeException("Failed to update KYC status", e);
        }
    }
}
