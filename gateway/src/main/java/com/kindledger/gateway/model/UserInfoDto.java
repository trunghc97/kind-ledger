package com.kindledger.gateway.model;

public class UserInfoDto {
    private String userId;
    private String username;
    private String email;
    private String role;
    private String walletAddress;
    private String walletStatus;

    public UserInfoDto() {}

    public UserInfoDto(String userId, String username, String email, String role, String walletAddress, String walletStatus) {
        this.userId = userId;
        this.username = username;
        this.email = email;
        this.role = role;
        this.walletAddress = walletAddress;
        this.walletStatus = walletStatus;
    }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public String getWalletAddress() { return walletAddress; }
    public void setWalletAddress(String walletAddress) { this.walletAddress = walletAddress; }
    public String getWalletStatus() { return walletStatus; }
    public void setWalletStatus(String walletStatus) { this.walletStatus = walletStatus; }
}
