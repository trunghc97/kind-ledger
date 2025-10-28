package com.kindledger.gateway.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
@Slf4j
public class BankMockService {
    public BankTransferResult transfer(String accountNumber, BigDecimal amount) {
        try { Thread.sleep(300); } catch (InterruptedException ignored) {}
        String bankRef = "MBTX-" + System.currentTimeMillis();
        log.info("[BANK MOCK] Transfer success from {} amount {}", accountNumber, amount);
        return new BankTransferResult(true, bankRef);
    }

    public record BankTransferResult(boolean success, String bankRef) {}
}
