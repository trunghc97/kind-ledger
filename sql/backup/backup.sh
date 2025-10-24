#!/bin/bash

# KindLedger Database Backup Script
# Usage: ./backup.sh [backup_name]

set -e

BACKUP_NAME=${1:-"backup_$(date +%Y%m%d_%H%M%S)"}
BACKUP_DIR="/backup"
CONTAINER_NAME="kindledger-postgres"

echo "Starting database backup: $BACKUP_NAME"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create database backup
echo "Creating PostgreSQL backup..."
docker exec $CONTAINER_NAME pg_dump -U postgres -d kindledger > "$BACKUP_DIR/${BACKUP_NAME}.sql"

# Create compressed backup
echo "Compressing backup..."
gzip "$BACKUP_DIR/${BACKUP_NAME}.sql"

# Create backup info file
cat > "$BACKUP_DIR/${BACKUP_NAME}.info" << EOF
Backup Name: $BACKUP_NAME
Created: $(date)
Database: kindledger
Container: $CONTAINER_NAME
Size: $(du -h "$BACKUP_DIR/${BACKUP_NAME}.sql.gz" | cut -f1)
EOF

echo "Backup completed: $BACKUP_DIR/${BACKUP_NAME}.sql.gz"
echo "Backup info: $BACKUP_DIR/${BACKUP_NAME}.info"
