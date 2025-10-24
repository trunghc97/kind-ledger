#!/bin/bash

# KindLedger Database Restore Script
# Usage: ./restore.sh <backup_file>

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la /backup/*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
CONTAINER_NAME="kindledger-postgres"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found"
    exit 1
fi

echo "Restoring database from: $BACKUP_FILE"

# Stop the application to prevent data corruption
echo "Stopping application services..."
docker-compose stop gateway frontend

# Drop and recreate database
echo "Recreating database..."
docker exec $CONTAINER_NAME psql -U postgres -c "DROP DATABASE IF EXISTS kindledger;"
docker exec $CONTAINER_NAME psql -U postgres -c "CREATE DATABASE kindledger;"

# Restore from backup
echo "Restoring database..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker exec -i $CONTAINER_NAME psql -U postgres -d kindledger
else
    docker exec -i $CONTAINER_NAME psql -U postgres -d kindledger < "$BACKUP_FILE"
fi

# Restart application services
echo "Starting application services..."
docker-compose start gateway frontend

echo "Database restore completed successfully!"
