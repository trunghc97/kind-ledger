package com.kindledger.gateway.controller;

import com.kindledger.gateway.entity.UserEntity;
import com.kindledger.gateway.model.LinkBankRequest;
import com.kindledger.gateway.repository.UserRepository;
import com.kindledger.gateway.service.BankMockService;
import com.kindledger.gateway.service.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class UserController {

    private final UserRepository userRepository;
    private final BankMockService bankMockService;
    private final WalletService walletService;

    @PostMapping("/users/{id}/link-bank")
    public ResponseEntity<Map<String, Object>> linkBank(@PathVariable("id") String id,
                                                        @RequestBody LinkBankRequest request) {
        String acc = request.getAccountNumber();
        if (acc == null || acc.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "accountNumber required"
            ));
        }

        UUID userUuid = parseUserId(id);
        Optional<UserEntity> userOpt = userRepository.findById(userUuid);
        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "User not found"
            ));
        }

        var bankResult = bankMockService.transfer(acc, java.math.BigDecimal.ONE);
        if (!bankResult.success()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Bank link failed"
            ));
        }

        walletService.activateWallet(userUuid);

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Wallet activated"
        ));
    }

    @GetMapping("/wallet/{address}/balance")
    public ResponseEntity<?> getWalletBalance(@PathVariable("address") String address) {
        try {
            var wallet = walletService.getByAddress(address);
            return ResponseEntity.ok(Map.of(
                "address", wallet.getAddress(),
                "cVndBalance", wallet.getBalance(),
                "status", wallet.getStatus()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(404).body(Map.of("error", "Wallet not found"));
        }
    }

    private UUID parseUserId(String id) {
        if (id.startsWith("user-")) {
            return UUID.fromString(id.substring(5));
        }
        return UUID.fromString(id);
    }
}
