package com.kindledger.gateway.service;

import com.kindledger.gateway.entity.WalletStatus;
import com.kindledger.gateway.model.BurnRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.Assert;

@Service
@RequiredArgsConstructor
@Slf4j
public class BurnService {

    private final WalletService walletService;
    private final BlockchainService blockchainService;

    public String burn(BurnRequest req) {
        Assert.notNull(req.getWalletAddress(), "walletAddress required");
        Assert.notNull(req.getAmount(), "amount required");
        Assert.isTrue(req.getAmount().signum() > 0, "Invalid amount");

        var wallet = walletService.getByAddress(req.getWalletAddress());
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException("Wallet not active yet");
        }

        var result = blockchainService.burnToken(req.getWalletAddress(), req.getAmount());
        return result.txId();
    }
}
