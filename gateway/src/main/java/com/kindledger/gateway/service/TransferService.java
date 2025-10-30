package com.kindledger.gateway.service;

import com.kindledger.gateway.entity.WalletStatus;
import com.kindledger.gateway.model.TransferRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.Assert;

@Service
@RequiredArgsConstructor
@Slf4j
public class TransferService {

    private final WalletService walletService;
    private final BlockchainService blockchainService;

    public String transfer(TransferRequest req) {
        Assert.notNull(req.getFromWalletAddress(), "fromWalletAddress required");
        Assert.notNull(req.getToWalletAddress(), "toWalletAddress required");
        Assert.notNull(req.getAmount(), "amount required");
        Assert.isTrue(req.getAmount().signum() > 0, "Invalid amount");

        var from = walletService.getByAddress(req.getFromWalletAddress());
        var to = walletService.getByAddress(req.getToWalletAddress());
        if (from.getStatus() != WalletStatus.ACTIVE || to.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException("Wallet not active yet");
        }

        var result = blockchainService.transferToken(req.getFromWalletAddress(), req.getToWalletAddress(), req.getAmount());
        return result.txId();
    }
}
