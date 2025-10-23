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
	r.GET("/api/charity/health", healthCheck)
	r.POST("/api/charity/endorse", endorseTransaction)
	r.GET("/api/charity/campaigns", getCampaigns)
	r.POST("/api/charity/create-campaign", createCampaign)
	r.POST("/api/charity/donate", processDonation)

	// Start server
	port := os.Getenv("PEER_PORT")
	if port == "" {
		port = "8083"
	}

	log.Printf("Charity Peer starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func connectToMongoDB() {
	// Connect to node-specific MongoDB
	nodeMongoURL := os.Getenv("MONGODB_URL")
	if nodeMongoURL == "" {
		nodeMongoURL = "mongodb://charity_admin:charity_password@mongodb-charity:27017/charity_ledger"
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

	nodeDB = nodeClient.Database("charity_ledger")

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
		"peerId":    "charity-peer",
		"endorsed":  true,
		"timestamp": time.Now(),
		"signature": "0xcharity_signature_" + request.TxHash,
	}

	_, err := nodeDB.Collection("endorsements").InsertOne(ctx, endorsement)
	if err != nil {
		log.Printf("Error saving endorsement: %v", err)
	}

	response := gin.H{
		"txHash":    request.TxHash,
		"peerId":    "charity-peer",
		"endorsed":  true,
		"signature": "0xcharity_signature_" + request.TxHash,
	}

	c.JSON(200, response)
}

func getCampaigns(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := nodeDB.Collection("campaigns").Find(ctx, map[string]interface{}{})
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to query campaigns"})
		return
	}
	defer cursor.Close(ctx)

	var campaigns []map[string]interface{}
	if err = cursor.All(ctx, &campaigns); err != nil {
		c.JSON(500, gin.H{"error": "Failed to decode campaigns"})
		return
	}

	response := gin.H{
		"campaigns": campaigns,
		"count":     len(campaigns),
	}

	c.JSON(200, response)
}

func createCampaign(c *gin.Context) {
	var request struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		Target      string `json:"target"`
		Duration    int    `json:"duration"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save campaign to both databases
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	campaign := map[string]interface{}{
		"campaignId":  "camp_" + time.Now().Format("20060102150405"),
		"title":       request.Title,
		"description": request.Description,
		"target":      request.Target,
		"duration":    request.Duration,
		"status":      "active",
		"createdAt":   time.Now(),
		"raised":      "0",
	}

	// Save to node database
	_, err := nodeDB.Collection("campaigns").InsertOne(ctx, campaign)
	if err != nil {
		log.Printf("Error saving campaign to node DB: %v", err)
	}

	// Save to shared database
	_, err = sharedDB.Collection("campaigns").InsertOne(ctx, campaign)
	if err != nil {
		log.Printf("Error saving campaign to shared DB: %v", err)
	}

	response := gin.H{
		"campaignId": campaign["campaignId"],
		"status":     "created",
		"message":    "Campaign created successfully",
	}

	c.JSON(200, response)
}

func processDonation(c *gin.Context) {
	var request struct {
		CampaignID string `json:"campaignId"`
		Amount     string `json:"amount"`
		Donor      string `json:"donor"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Save donation to both databases
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	donation := map[string]interface{}{
		"txHash":     "0xdonation_" + time.Now().Format("20060102150405"),
		"campaignId": request.CampaignID,
		"amount":     request.Amount,
		"donor":      request.Donor,
		"timestamp":  time.Now(),
		"status":     "confirmed",
	}

	// Save to node database
	_, err := nodeDB.Collection("donations").InsertOne(ctx, donation)
	if err != nil {
		log.Printf("Error saving donation to node DB: %v", err)
	}

	// Save to shared database
	_, err = sharedDB.Collection("transactions").InsertOne(ctx, donation)
	if err != nil {
		log.Printf("Error saving donation to shared DB: %v", err)
	}

	response := gin.H{
		"txHash":     donation["txHash"],
		"campaignId": request.CampaignID,
		"amount":     request.Amount,
		"status":     "success",
	}

	c.JSON(200, response)
}

func healthCheck(c *gin.Context) {
	response := gin.H{
		"status":   "UP",
		"service":  "charity-peer",
		"nodeDb":   "connected",
		"sharedDb": "connected",
	}

	c.JSON(200, response)
}
