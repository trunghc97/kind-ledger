package com.kindledger.gateway.service;

import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class SessionService {

    private final ConcurrentHashMap<String, UUID> tokenToUserId = new ConcurrentHashMap<>();

    public void store(String token, UUID userId) {
        if (token == null || token.isBlank() || userId == null) return;
        tokenToUserId.put(token, userId);
    }

    public UUID getUserId(String token) {
        if (token == null || token.isBlank()) return null;
        return tokenToUserId.get(token);
    }
}
