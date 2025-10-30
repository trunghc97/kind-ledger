package com.kindledger.gateway.controller;

import com.kindledger.gateway.model.BurnRequest;
import com.kindledger.gateway.model.TransferRequest;
import com.kindledger.gateway.service.BurnService;
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

    @PostMapping("/transfer")
    public ResponseEntity<Map<String, Object>> transfer(@RequestBody TransferRequest req) {
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
