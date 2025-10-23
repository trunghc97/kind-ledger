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
	r.GET("/api/observer/health", healthCheck)
	r.GET("/api/observer/audit", getAuditLogs)
	r.POST("/api/observer/audit", createAuditLog)
	r.GET("/api/observer/compliance", getComplianceReport)

	// Start server
	port := os.Getenv("OBSERVER_PORT")
	if port == "" {
		port = "7070"
	}

	log.Printf("Gov Observer starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func connectToMongoDB() {
	// Connect to node-specific MongoDB
	nodeMongoURL := os.Getenv("MONGODB_URL")
	if nodeMongoURL == "" {
		nodeMongoURL = "mongodb://gov_admin:gov_password@mongodb-gov:27017/gov_ledger"
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

	nodeDB = nodeClient.Database("gov_ledger")

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

func getAuditLogs(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := nodeDB.Collection("audit_logs").Find(ctx, map[string]interface{}{})
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to query audit logs"})
		return
	}
	defer cursor.Close(ctx)

	var logs []map[string]interface{}
	if err = cursor.All(ctx, &logs); err != nil {
		c.JSON(500, gin.H{"error": "Failed to decode audit logs"})
		return
	}

	response := gin.H{
		"auditLogs": logs,
		"count":     len(logs),
	}

	c.JSON(200, response)
}

func createAuditLog(c *gin.Context) {
	var request struct {
		Action    string `json:"action"`
		Entity    string `json:"entity"`
		Details   string `json:"details"`
		Timestamp string `json:"timestamp"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save audit log to both databases
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	auditLog := map[string]interface{}{
		"action":     request.Action,
		"entity":     request.Entity,
		"details":    request.Details,
		"timestamp":  time.Now(),
		"observerId": "gov-observer",
	}

	// Save to node database
	_, err := nodeDB.Collection("audit_logs").InsertOne(ctx, auditLog)
	if err != nil {
		log.Printf("Error saving audit log to node DB: %v", err)
	}

	// Save to shared database
	_, err = sharedDB.Collection("audit_logs").InsertOne(ctx, auditLog)
	if err != nil {
		log.Printf("Error saving audit log to shared DB: %v", err)
	}

	response := gin.H{
		"status":     "logged",
		"action":     request.Action,
		"entity":     request.Entity,
		"observerId": "gov-observer",
	}

	c.JSON(200, response)
}

func getComplianceReport(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Get transaction count from shared database
	txCount, err := sharedDB.Collection("transactions").CountDocuments(ctx, map[string]interface{}{})
	if err != nil {
		log.Printf("Error counting transactions: %v", err)
	}

	// Get campaign count
	campaignCount, err := sharedDB.Collection("campaigns").CountDocuments(ctx, map[string]interface{}{})
	if err != nil {
		log.Printf("Error counting campaigns: %v", err)
	}

	// Get block count
	blockCount, err := sharedDB.Collection("blocks").CountDocuments(ctx, map[string]interface{}{})
	if err != nil {
		log.Printf("Error counting blocks: %v", err)
	}

	response := gin.H{
		"reportDate":        time.Now().Format("2006-01-02"),
		"totalTransactions": txCount,
		"totalCampaigns":    campaignCount,
		"totalBlocks":       blockCount,
		"complianceStatus":  "compliant",
		"observerId":        "gov-observer",
	}

	c.JSON(200, response)
}

func healthCheck(c *gin.Context) {
	response := gin.H{
		"status":   "UP",
		"service":  "gov-observer",
		"nodeDb":   "connected",
		"sharedDb": "connected",
	}

	c.JSON(200, response)
}
