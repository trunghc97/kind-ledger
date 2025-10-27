FROM openjdk:21-jdk-slim

# Install Maven and wget for health checks
RUN apt-get update && apt-get install -y maven wget && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create Maven cache directory
RUN mkdir -p /root/.m2

# Copy pom.xml first for better caching
COPY pom.xml .

# Download dependencies (this layer will be cached if pom.xml doesn't change)
# Use existing cache from volume if available
RUN mvn dependency:go-offline -B || mvn dependency:resolve -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Create non-root user for security
RUN useradd -m -u 1001 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Run the application
CMD ["java", "-jar", "target/gateway-1.0.0.jar"]
