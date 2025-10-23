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
	r.GET("/api/orderer/health", healthCheck)
	r.POST("/api/orderer/order", orderTransaction)
	r.GET("/api/orderer/blocks", getBlocks)
	r.POST("/api/orderer/create-block", createBlock)

	// Start server
	port := os.Getenv("ORDERER_PORT")
	if port == "" {
		port = "7050"
	}

	log.Printf("Orderer starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func connectToMongoDB() {
	// Connect to node-specific MongoDB
	nodeMongoURL := os.Getenv("MONGODB_URL")
	if nodeMongoURL == "" {
		nodeMongoURL = "mongodb://orderer_admin:orderer_password@mongodb-orderer:27017/orderer_ledger"
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

	nodeDB = nodeClient.Database("orderer_ledger")

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

func orderTransaction(c *gin.Context) {
	var request struct {
		TxHash string `json:"txHash"`
		Data   string `json:"data"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save ordered transaction
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	order := map[string]interface{}{
		"txHash":    request.TxHash,
		"ordererId": os.Getenv("ORDERER_ID"),
		"ordered":   true,
		"timestamp": time.Now(),
		"sequence":  time.Now().UnixNano(),
	}

	_, err := nodeDB.Collection("orders").InsertOne(ctx, order)
	if err != nil {
		log.Printf("Error saving order: %v", err)
	}

	response := gin.H{
		"txHash":    request.TxHash,
		"ordererId": os.Getenv("ORDERER_ID"),
		"ordered":   true,
		"sequence":  order["sequence"],
	}

	c.JSON(200, response)
}

func getBlocks(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := nodeDB.Collection("blocks").Find(ctx, map[string]interface{}{})
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to query blocks"})
		return
	}
	defer cursor.Close(ctx)

	var blocks []map[string]interface{}
	if err = cursor.All(ctx, &blocks); err != nil {
		c.JSON(500, gin.H{"error": "Failed to decode blocks"})
		return
	}

	response := gin.H{
		"ordererId": os.Getenv("ORDERER_ID"),
		"blocks":    blocks,
		"count":     len(blocks),
	}

	c.JSON(200, response)
}

func createBlock(c *gin.Context) {
	var request struct {
		Transactions []string `json:"transactions"`
		PreviousHash string   `json:"previousHash"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Create new block
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	blockNumber := time.Now().Unix()
	block := map[string]interface{}{
		"blockNumber":  blockNumber,
		"hash":         "0xblock_" + time.Now().Format("20060102150405"),
		"previousHash": request.PreviousHash,
		"transactions": request.Transactions,
		"timestamp":    time.Now(),
		"ordererId":    os.Getenv("ORDERER_ID"),
		"size":         len(request.Transactions),
	}

	// Save to node database
	_, err := nodeDB.Collection("blocks").InsertOne(ctx, block)
	if err != nil {
		log.Printf("Error saving block to node DB: %v", err)
	}

	// Save to shared database
	_, err = sharedDB.Collection("blocks").InsertOne(ctx, block)
	if err != nil {
		log.Printf("Error saving block to shared DB: %v", err)
	}

	response := gin.H{
		"blockNumber": blockNumber,
		"hash":        block["hash"],
		"status":      "created",
		"ordererId":   os.Getenv("ORDERER_ID"),
	}

	c.JSON(200, response)
}

func healthCheck(c *gin.Context) {
	response := gin.H{
		"status":    "UP",
		"service":   "orderer",
		"ordererId": os.Getenv("ORDERER_ID"),
		"nodeDb":    "connected",
		"sharedDb":  "connected",
	}

	c.JSON(200, response)
}
