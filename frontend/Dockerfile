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

# Install nginx
RUN apk add --no-cache nginx

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built files to nginx html directory
RUN mkdir -p /usr/share/nginx/html && \
    cp -r dist/kindledger-frontend/* /usr/share/nginx/html/

# Expose port
EXPOSE 4200

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:4200 || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
