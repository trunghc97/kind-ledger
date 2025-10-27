FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create node_modules directory for volume mount
RUN mkdir -p /app/node_modules

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies (this layer will be cached if package.json doesn't change)
# Use existing cache from volume if available
RUN npm install --legacy-peer-deps --omit=dev || npm ci --legacy-peer-deps --omit=dev
RUN npm cache clean --force

# Copy source code
COPY . .

# Create wallet directory
RUN mkdir -p wallet

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000 || exit 1

# Start the application
CMD ["npm", "start"]
