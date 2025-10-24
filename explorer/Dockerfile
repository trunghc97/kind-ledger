FROM node:18-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY server.js ./

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8088/api/health || exit 1

# Expose port
EXPOSE 8088

# Start the explorer
CMD ["node", "server.js"]
