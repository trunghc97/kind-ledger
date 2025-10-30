package com.kindledger.gateway.service;

import com.kindledger.gateway.entity.TokenTransaction;
import com.kindledger.gateway.model.DepositRequest;
import com.kindledger.gateway.model.DepositResponse;
import com.kindledger.gateway.repository.TokenTransactionRepository;
import com.kindledger.gateway.entity.WalletStatus;
import com.kindledger.gateway.service.BankMockService.BankTransferResult;
import com.kindledger.gateway.service.BlockchainService.BlockchainMintResult;
import com.kindledger.gateway.util.HashUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.Assert;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class DepositService {

    private final BankMockService bankMockService;
    private final BlockchainService blockchainService;
    private final TokenTransactionRepository txRepo;
    private final WalletService walletService;

    public DepositResponse deposit(DepositRequest req) {
        Assert.notNull(req.getWalletAddress(), "walletAddress required");
        Assert.notNull(req.getAmount(), "amount required");
        Assert.isTrue(req.getAmount().compareTo(BigDecimal.ZERO) > 0, "Invalid amount");

        // Validate wallet ACTIVE
        var wallet = walletService.getByAddress(req.getWalletAddress());
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException("Wallet not active yet");
        }

        String txRef = "TX" + System.currentTimeMillis();
        String tokenHash = HashUtil.sha256(req.getAmount() + req.getWalletAddress() + txRef);
        String status = "SUCCESS";
        String txId = null;
        String blockHash = null;
        String message;

        try {
            // Step 1: mock bank transfer
            BankTransferResult bankResult = bankMockService.transfer(null, req.getAmount());
            if (!bankResult.success()) {
                throw new RuntimeException("Bank transfer failed");
            }

            // Step 2: mint token on blockchain (Fabric) - may fallback internally
            BlockchainMintResult bcResult = blockchainService.mintToken(req.getWalletAddress(), req.getAmount(), tokenHash);
            txId = bcResult.txId();
            blockHash = bcResult.blockHash();
            message = String.format("Minted %,.6f cVND to wallet %s", req.getAmount(), req.getWalletAddress());
        } catch (Exception ex) {
            log.warn("Deposit fallback due to error: {}", ex.getMessage());
            status = "PENDING_BLOCKCHAIN";
            txId = txId == null ? ("FALLBACK-" + System.currentTimeMillis()) : txId;
            message = "Bank success, blockchain pending";
        }

        // Save DB regardless, with status
        TokenTransaction tx = new TokenTransaction();
        tx.setTxRef(txRef);
        tx.setWalletAddress(req.getWalletAddress());
        tx.setAmount(req.getAmount().setScale(6, RoundingMode.DOWN));
        tx.setTokenHash(tokenHash);
        tx.setBankRef("OK");
        tx.setBlockchainTxId(txId);
        tx.setBlockHash(blockHash);
        tx.setCreatedAt(LocalDateTime.now());
        tx.setStatus(status);
        txRepo.save(tx);

        return new DepositResponse(txRef, txId, tokenHash, status, message);
    }
}
