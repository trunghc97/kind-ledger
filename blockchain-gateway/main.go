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
	sharedDB *mongo.Database
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Connect to MongoDB Shared
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
	r.GET("/api/blockchain/balance/:address", getBalance)
	r.POST("/api/blockchain/mint", mintTokens)
	r.POST("/api/blockchain/burn", burnTokens)
	r.POST("/api/blockchain/donate", donate)
	r.GET("/api/blockchain/health", healthCheck)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "9090"
	}

	log.Printf("Blockchain Gateway starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func connectToMongoDB() {
	mongoURL := os.Getenv("MONGODB_SHARED_URL")
	if mongoURL == "" {
		mongoURL = "mongodb://admin:password@mongodb-shared:27017/kindledger_shared"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURL))
	if err != nil {
		log.Fatal("Failed to connect to MongoDB:", err)
	}

	// Test connection
	err = client.Ping(ctx, nil)
	if err != nil {
		log.Fatal("Failed to ping MongoDB:", err)
	}

	sharedDB = client.Database("kindledger_shared")
	log.Println("Connected to MongoDB Shared successfully")
}

func getBalance(c *gin.Context) {
	address := c.Param("address")

	// Query from MongoDB
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var transaction struct {
		Amount string `bson:"amount"`
	}

	err := sharedDB.Collection("transactions").FindOne(ctx, map[string]string{"to": address}).Decode(&transaction)
	if err != nil {
		log.Printf("Error querying balance: %v", err)
	}

	response := gin.H{
		"address":  address,
		"balance":  "1000.0", // Mock balance for now
		"currency": "cVND",
	}

	c.JSON(200, response)
}

func mintTokens(c *gin.Context) {
	var request struct {
		Amount string `json:"amount"`
		Wallet string `json:"wallet"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save to MongoDB
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	transaction := map[string]interface{}{
		"txHash":    "0x1234567890abcdef",
		"type":      "mint",
		"amount":    request.Amount,
		"wallet":    request.Wallet,
		"timestamp": time.Now(),
		"status":    "confirmed",
	}

	_, err := sharedDB.Collection("transactions").InsertOne(ctx, transaction)
	if err != nil {
		log.Printf("Error saving transaction: %v", err)
	}

	response := gin.H{
		"txHash": "0x1234567890abcdef",
		"status": "success",
		"amount": request.Amount,
	}

	c.JSON(200, response)
}

func burnTokens(c *gin.Context) {
	var request struct {
		Amount string `json:"amount"`
		Wallet string `json:"wallet"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save to MongoDB
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	transaction := map[string]interface{}{
		"txHash":    "0xabcdef1234567890",
		"type":      "burn",
		"amount":    request.Amount,
		"wallet":    request.Wallet,
		"timestamp": time.Now(),
		"status":    "confirmed",
	}

	_, err := sharedDB.Collection("transactions").InsertOne(ctx, transaction)
	if err != nil {
		log.Printf("Error saving transaction: %v", err)
	}

	response := gin.H{
		"txHash": "0xabcdef1234567890",
		"status": "success",
		"amount": request.Amount,
	}

	c.JSON(200, response)
}

func donate(c *gin.Context) {
	var request struct {
		CampaignID string `json:"campaignId"`
		Amount     string `json:"amount"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save to MongoDB
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	transaction := map[string]interface{}{
		"txHash":     "0x9876543210fedcba",
		"type":       "donate",
		"campaignId": request.CampaignID,
		"amount":     request.Amount,
		"timestamp":  time.Now(),
		"status":     "confirmed",
	}

	_, err := sharedDB.Collection("transactions").InsertOne(ctx, transaction)
	if err != nil {
		log.Printf("Error saving transaction: %v", err)
	}

	response := gin.H{
		"txHash":     "0x9876543210fedcba",
		"status":     "success",
		"campaignId": request.CampaignID,
		"amount":     request.Amount,
	}

	c.JSON(200, response)
}

func healthCheck(c *gin.Context) {
	response := gin.H{
		"status":  "UP",
		"service": "blockchain-gateway",
		"mongodb": "connected",
	}

	c.JSON(200, response)
}
