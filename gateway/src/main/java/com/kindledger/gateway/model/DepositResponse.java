package com.kindledger.gateway.model;

public class DepositResponse {
    private String txRef;
    private String txId;
    private String tokenHash;
    private String status;
    private String message;

    public DepositResponse() {}

    public DepositResponse(String txRef, String txId, String tokenHash, String status, String message) {
        this.txRef = txRef;
        this.txId = txId;
        this.tokenHash = tokenHash;
        this.status = status;
        this.message = message;
    }

    public String getTxRef() { return txRef; }
    public void setTxRef(String txRef) { this.txRef = txRef; }
    public String getTxId() { return txId; }
    public void setTxId(String txId) { this.txId = txId; }
    public String getTokenHash() { return tokenHash; }
    public void setTokenHash(String tokenHash) { this.tokenHash = tokenHash; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
