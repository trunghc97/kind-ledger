package com.kindledger.gateway.controller;

import com.kindledger.gateway.model.DepositRequest;
import com.kindledger.gateway.model.DepositResponse;
import com.kindledger.gateway.service.DepositService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DepositController {

    private final DepositService depositService;

    @PostMapping("/deposit")
    public ResponseEntity<DepositResponse> deposit(@RequestBody DepositRequest request) {
        DepositResponse resp = depositService.deposit(request);
        return ResponseEntity.ok(resp);
    }
}
