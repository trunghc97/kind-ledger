#!/bin/bash

# KindLedger System Management Scripts
# Backup script

set -e

BACKUP_NAME="kindledger_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backups/$BACKUP_NAME"

echo "💾 Creating KindLedger system backup: $BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database
echo "🗄️  Backing up PostgreSQL database..."
docker exec kindledger-postgres pg_dump -U postgres -d kindledger > "$BACKUP_DIR/database.sql"

# Backup MongoDB
echo "🍃 Backing up MongoDB..."
docker exec kindledger-mongodb mongodump --db kindledger --archive > "$BACKUP_DIR/mongodb.archive"

# Backup IPFS data
echo "📁 Backing up IPFS data..."
docker cp kindledger-ipfs:/data/ipfs "$BACKUP_DIR/ipfs/"

# Backup blockchain data
echo "⛓️  Backing up blockchain data..."
docker cp kindledger-besu-validator:/data "$BACKUP_DIR/besu-validator/"
docker cp kindledger-besu-observer:/data "$BACKUP_DIR/besu-observer/"

# Create backup info
cat > "$BACKUP_DIR/backup_info.txt" << EOF
KindLedger System Backup
=======================
Backup Name: $BACKUP_NAME
Created: $(date)
System Version: 1.0.0

Contents:
- database.sql: PostgreSQL database dump
- mongodb.archive: MongoDB archive
- ipfs/: IPFS data directory
- besu-validator/: Besu validator data
- besu-observer/: Besu observer data

To restore:
1. Stop the system: ./scripts/stop.sh
2. Restore data to ./data/ directory
3. Start the system: ./scripts/start.sh
EOF

# Compress backup
echo "📦 Compressing backup..."
tar -czf "backups/${BACKUP_NAME}.tar.gz" -C "$BACKUP_DIR" .

# Remove temporary directory
rm -rf "$BACKUP_DIR"

echo "✅ Backup completed: backups/${BACKUP_NAME}.tar.gz"
echo "📊 Backup size: $(du -h "backups/${BACKUP_NAME}.tar.gz" | cut -f1)"
