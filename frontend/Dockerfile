FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create node_modules directory for volume mount
RUN mkdir -p /app/node_modules

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies (this layer will be cached if package.json doesn't change)
# Use existing cache from volume if available
RUN npm install --legacy-peer-deps || npm ci --legacy-peer-deps
RUN npm cache clean --force

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Install serve globally
RUN npm install -g serve

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001
USER nextjs

# Expose port
EXPOSE 4200

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:4200 || exit 1

# Start the application
CMD ["serve", "-s", "dist/kindledger-frontend", "-l", "4200"]
