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
	r.GET("/api/peer/health", healthCheck)
	r.POST("/api/peer/endorse", endorseTransaction)
	r.GET("/api/peer/ledger", getLedger)
	r.POST("/api/peer/commit", commitTransaction)

	// Start server
	port := os.Getenv("PEER_PORT")
	if port == "" {
		port = "8082"
	}

	log.Printf("MB Bank Peer starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func connectToMongoDB() {
	// Connect to node-specific MongoDB
	nodeMongoURL := os.Getenv("MONGODB_URL")
	if nodeMongoURL == "" {
		nodeMongoURL = "mongodb://mb_admin:mb_password@mongodb-mb:27017/mb_ledger"
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

	nodeDB = nodeClient.Database("mb_ledger")

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

func endorseTransaction(c *gin.Context) {
	var request struct {
		TxHash string `json:"txHash"`
		Data   string `json:"data"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save endorsement to node database
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	endorsement := map[string]interface{}{
		"txHash":    request.TxHash,
		"peerId":    "mb-peer",
		"endorsed":  true,
		"timestamp": time.Now(),
		"signature": "0xmb_signature_" + request.TxHash,
	}

	_, err := nodeDB.Collection("endorsements").InsertOne(ctx, endorsement)
	if err != nil {
		log.Printf("Error saving endorsement: %v", err)
	}

	response := gin.H{
		"txHash":    request.TxHash,
		"peerId":    "mb-peer",
		"endorsed":  true,
		"signature": "0xmb_signature_" + request.TxHash,
	}

	c.JSON(200, response)
}

func getLedger(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := nodeDB.Collection("transactions").Find(ctx, map[string]interface{}{})
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to query ledger"})
		return
	}
	defer cursor.Close(ctx)

	var transactions []map[string]interface{}
	if err = cursor.All(ctx, &transactions); err != nil {
		c.JSON(500, gin.H{"error": "Failed to decode transactions"})
		return
	}

	response := gin.H{
		"peerId":       "mb-peer",
		"transactions": transactions,
		"count":        len(transactions),
	}

	c.JSON(200, response)
}

func commitTransaction(c *gin.Context) {
	var request struct {
		TxHash string `json:"txHash"`
		Block  string `json:"block"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save committed transaction
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	transaction := map[string]interface{}{
		"txHash":    request.TxHash,
		"block":     request.Block,
		"peerId":    "mb-peer",
		"committed": true,
		"timestamp": time.Now(),
	}

	_, err := nodeDB.Collection("committed_transactions").InsertOne(ctx, transaction)
	if err != nil {
		log.Printf("Error saving committed transaction: %v", err)
	}

	response := gin.H{
		"txHash":    request.TxHash,
		"block":     request.Block,
		"committed": true,
	}

	c.JSON(200, response)
}

func healthCheck(c *gin.Context) {
	response := gin.H{
		"status":   "UP",
		"service":  "mb-peer",
		"nodeDb":   "connected",
		"sharedDb": "connected",
	}

	c.JSON(200, response)
}
