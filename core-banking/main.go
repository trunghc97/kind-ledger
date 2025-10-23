package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	nodeDB   *mongo.Database
	sharedDB *mongo.Database
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Connect to MongoDB
	connectToMongoDB()

	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	// Create router
	r := gin.Default()

	// CORS middleware
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Routes
	r.GET("/api/banking/health", healthCheck)
	r.GET("/api/banking/accounts", getAccounts)
	r.POST("/api/banking/transfer", processTransfer)
	r.GET("/api/banking/transactions", getTransactions)

	// Start server
	port := os.Getenv("CORE_BANKING_PORT")
	if port == "" {
		port = "8089"
	}

	log.Printf("Core Banking starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func connectToMongoDB() {
	// Connect to node-specific MongoDB
	nodeMongoURL := os.Getenv("MONGODB_URL")
	if nodeMongoURL == "" {
		nodeMongoURL = "mongodb://banking_admin:banking_password@mongodb-banking:27017/banking_ledger"
	}

	// Connect to shared MongoDB
	sharedMongoURL := os.Getenv("MONGODB_SHARED_URL")
	if sharedMongoURL == "" {
		sharedMongoURL = "mongodb://admin:password@mongodb-shared:27017/kindledger_shared"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Connect to node database
	nodeClient, err := mongo.Connect(ctx, options.Client().ApplyURI(nodeMongoURL))
	if err != nil {
		log.Fatal("Failed to connect to node MongoDB:", err)
	}

	err = nodeClient.Ping(ctx, nil)
	if err != nil {
		log.Fatal("Failed to ping node MongoDB:", err)
	}

	nodeDB = nodeClient.Database("banking_ledger")

	// Connect to shared database
	sharedClient, err := mongo.Connect(ctx, options.Client().ApplyURI(sharedMongoURL))
	if err != nil {
		log.Fatal("Failed to connect to shared MongoDB:", err)
	}

	err = sharedClient.Ping(ctx, nil)
	if err != nil {
		log.Fatal("Failed to ping shared MongoDB:", err)
	}

	sharedDB = sharedClient.Database("kindledger_shared")
	log.Println("Connected to MongoDB successfully")
}

func getAccounts(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := nodeDB.Collection("accounts").Find(ctx, map[string]interface{}{})
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to query accounts"})
		return
	}
	defer cursor.Close(ctx)

	var accounts []map[string]interface{}
	if err = cursor.All(ctx, &accounts); err != nil {
		c.JSON(500, gin.H{"error": "Failed to decode accounts"})
		return
	}

	response := gin.H{
		"accounts": accounts,
		"count":    len(accounts),
	}

	c.JSON(200, response)
}

func processTransfer(c *gin.Context) {
	var request struct {
		From   string `json:"from"`
		To     string `json:"to"`
		Amount string `json:"amount"`
		Type   string `json:"type"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save transfer to both databases
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	transfer := map[string]interface{}{
		"txHash":    "0xbanking_" + time.Now().Format("20060102150405"),
		"from":      request.From,
		"to":        request.To,
		"amount":    request.Amount,
		"type":      request.Type,
		"timestamp": time.Now(),
		"status":    "confirmed",
		"bankingId": "core-banking",
	}

	// Save to node database
	_, err := nodeDB.Collection("transfers").InsertOne(ctx, transfer)
	if err != nil {
		log.Printf("Error saving transfer to node DB: %v", err)
	}

	// Save to shared database
	_, err = sharedDB.Collection("transactions").InsertOne(ctx, transfer)
	if err != nil {
		log.Printf("Error saving transfer to shared DB: %v", err)
	}

	response := gin.H{
		"txHash":    transfer["txHash"],
		"from":      request.From,
		"to":        request.To,
		"amount":    request.Amount,
		"status":    "success",
		"bankingId": "core-banking",
	}

	c.JSON(200, response)
}

func getTransactions(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := nodeDB.Collection("transfers").Find(ctx, map[string]interface{}{})
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to query transactions"})
		return
	}
	defer cursor.Close(ctx)

	var transactions []map[string]interface{}
	if err = cursor.All(ctx, &transactions); err != nil {
		c.JSON(500, gin.H{"error": "Failed to decode transactions"})
		return
	}

	response := gin.H{
		"transactions": transactions,
		"count":        len(transactions),
		"bankingId":    "core-banking",
	}

	c.JSON(200, response)
}

func healthCheck(c *gin.Context) {
	response := gin.H{
		"status":   "UP",
		"service":  "core-banking",
		"nodeDb":   "connected",
		"sharedDb": "connected",
	}

	c.JSON(200, response)
}
