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
    if err := ctx.GetStub().PutState("balance_"+walletAddress, []byte(amount)); err != nil {
        return err
    }
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

func main() {
    cc, err := contractapi.NewChaincode(new(CvndTokenContract))
    if err != nil {
        panic(err)
    }
    if err := cc.Start(); err != nil {
        panic(err)
    }
}
