package com.kindledger.gateway.model;

public class AuthResponse {
    private String token;
    private String userId;
    private String username;
    private String email;
    private String fullName;
    private String role;
    private String walletAddres;
    private String walletStatus;

    // Constructors
    public AuthResponse() {
    }

    public AuthResponse(String token, String userId, String username, String email, String fullName, String role, String walletId, String walletStatus) {
        this.token = token;
        this.userId = userId;
        this.username = username;
        this.email = email;
        this.fullName = fullName;
        this.role = role;
        this.walletAddres = walletAddres;
        this.walletStatus = walletStatus;
    }

    // Getters and Setters
    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getWalletAddress() {
        return walletAddres;
    }

    public void setWalletAddress(String walletAddres) {
        this.walletAddres = walletAddres;
    }

    public String getWalletStatus() {
        return walletStatus;
    }

    public void setWalletStatus(String walletStatus) {
        this.walletStatus = walletStatus;
    }
}
