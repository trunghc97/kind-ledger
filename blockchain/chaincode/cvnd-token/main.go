package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type CvndTokenContract struct {
	contractapi.Contract
}

type MintEvent struct {
	WalletAddress string `json:"walletAddress"`
	Amount        string `json:"amount"`
	TokenHash     string `json:"tokenHash"`
	Timestamp     int64  `json:"timestamp"`
}

type TransferEvent struct {
    From      string `json:"from"`
    To        string `json:"to"`
    Amount    string `json:"amount"`
    Timestamp int64  `json:"timestamp"`
}

func (c *CvndTokenContract) Mint(ctx contractapi.TransactionContextInterface, walletAddress string, amount string, tokenHash string) error {
	if walletAddress == "" || amount == "" {
		return fmt.Errorf("invalid arguments")
	}
	key := fmt.Sprintf("mint_%s", tokenHash)
	payload := MintEvent{WalletAddress: walletAddress, Amount: amount, TokenHash: tokenHash, Timestamp: time.Now().Unix()}
	b, _ := json.Marshal(payload)
	if err := ctx.GetStub().PutState(key, b); err != nil {
		return err
	}
	// Đọc số dư cũ
	balanceKey := "balance_" + walletAddress
	oldBytes, _ := ctx.GetStub().GetState(balanceKey)
	var oldAmount float64 = 0
	if oldBytes != nil {
		fmt.Sscanf(string(oldBytes), "%f", &oldAmount)
	}
	var mintAmount float64
	fmt.Sscanf(amount, "%f", &mintAmount)
	newBalance := oldAmount + mintAmount
	if err := ctx.GetStub().PutState(balanceKey, []byte(fmt.Sprintf("%.6f", newBalance))); err != nil {
		return err
	}
	_ = ctx.GetStub().SetEvent("Mint", b)
	return nil
}

func (c *CvndTokenContract) BalanceOf(ctx contractapi.TransactionContextInterface, walletAddress string) (string, error) {
	v, err := ctx.GetStub().GetState("balance_" + walletAddress)
	if err != nil {
		return "", err
	}
	if v == nil {
		return "0", nil
	}
	return string(v), nil
}

func (c *CvndTokenContract) Transfer(ctx contractapi.TransactionContextInterface, fromWallet string, toWallet string, amount string) error {
    if fromWallet == "" || toWallet == "" || amount == "" {
        return fmt.Errorf("invalid arguments")
    }

    // Read balances
    fromKey := "balance_" + fromWallet
    toKey := "balance_" + toWallet

    fromBytes, err := ctx.GetStub().GetState(fromKey)
    if err != nil {
        return err
    }
    var fromAmount float64 = 0
    if fromBytes != nil {
        fmt.Sscanf(string(fromBytes), "%f", &fromAmount)
    }

    var transferAmount float64
    fmt.Sscanf(amount, "%f", &transferAmount)
    if transferAmount <= 0 {
        return fmt.Errorf("amount must be positive")
    }
    if fromAmount < transferAmount {
        return fmt.Errorf("insufficient balance")
    }

    // Read to balance
    toBytes, err := ctx.GetStub().GetState(toKey)
    if err != nil {
        return err
    }
    var toAmount float64 = 0
    if toBytes != nil {
        fmt.Sscanf(string(toBytes), "%f", &toAmount)
    }

    // Update balances
    newFrom := fromAmount - transferAmount
    newTo := toAmount + transferAmount

    if err := ctx.GetStub().PutState(fromKey, []byte(fmt.Sprintf("%.6f", newFrom))); err != nil {
        return err
    }
    if err := ctx.GetStub().PutState(toKey, []byte(fmt.Sprintf("%.6f", newTo))); err != nil {
        return err
    }

    // Emit event
    evt := TransferEvent{From: fromWallet, To: toWallet, Amount: amount, Timestamp: time.Now().Unix()}
    b, _ := json.Marshal(evt)
    _ = ctx.GetStub().SetEvent("Transfer", b)
    return nil
}

func main() {
	cc, err := contractapi.NewChaincode(new(CvndTokenContract))
	if err != nil {
		panic(err)
	}
	if err := cc.Start(); err != nil {
		panic(err)
	}
}
