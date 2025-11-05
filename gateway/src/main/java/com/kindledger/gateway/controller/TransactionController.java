package com.kindledger.gateway.controller;

import com.kindledger.gateway.model.BurnRequest;
import com.kindledger.gateway.model.TransferRequest;
import com.kindledger.gateway.service.BurnService;
import com.kindledger.gateway.service.SessionService;
import com.kindledger.gateway.service.WalletService;
import com.kindledger.gateway.service.TransferService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class TransactionController {

    private final TransferService transferService;
    private final BurnService burnService;
    private final SessionService sessionService;
    private final WalletService walletService;

    @PostMapping("/transfer")
    public ResponseEntity<Map<String, Object>> transfer(@RequestBody TransferRequest req,
                                                        @RequestHeader(value = "Authorization", required = false) String authorization) {
        // Nếu không truyền fromWalletAddress: lấy từ token phiên đăng nhập
        if (req.getFromWalletAddress() == null || req.getFromWalletAddress().isBlank()) {
            String token = (authorization != null && authorization.startsWith("Bearer "))
                    ? authorization.substring(7) : authorization;
            var userId = sessionService.getUserId(token);
            if (userId == null) {
                return ResponseEntity.status(401).body(Map.of(
                        "success", false,
                        "message", "Unauthorized"
                ));
            }
            var wallet = walletService.getByUserId(userId);
            req.setFromWalletAddress(wallet.getAddress());
        }
        String txId = transferService.transfer(req);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "txId", txId
        ));
    }

    @PostMapping("/burn")
    public ResponseEntity<Map<String, Object>> burn(@RequestBody BurnRequest req) {
        String txId = burnService.burn(req);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "txId", txId
        ));
    }
}
