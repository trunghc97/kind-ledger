# Multi-stage build for better caching and smaller image
FROM maven:3.8-openjdk-17 as builder

WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests -Dmaven.test.skip=true

# Production stage
FROM eclipse-temurin:17-jre

# Install necessary packages
RUN apt-get update && \
    apt-get install -y wget curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1001 appuser || true

WORKDIR /app

# Copy jar from builder stage
COPY --from=builder /app/target/kindledger-gateway-1.0.0.jar app.jar

# Change ownership
RUN chown appuser:appuser app.jar || chown 1001:1001 app.jar

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Expose port
EXPOSE 8080

# JVM optimization for containers
ENV JAVA_OPTS="-Xmx1g -Xms512m -XX:+UseG1GC -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Run the application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
