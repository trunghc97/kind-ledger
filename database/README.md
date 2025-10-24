# Kind-Ledger Database Setup

This directory contains the database configuration and setup scripts for the Kind-Ledger system.

## 🗄️ Database Architecture

The Kind-Ledger system uses a multi-database architecture:

- **PostgreSQL**: Primary relational database for structured data (campaigns, donations, users, transactions)
- **MongoDB**: Document database for flexible data storage and analytics
- **Redis**: Cache and session store for performance optimization

## 📁 Directory Structure

```
database/
├── init/                          # Database initialization scripts
│   ├── 01-init-schema.sql        # PostgreSQL schema and tables
│   └── 02-sample-data.sql        # Sample data for testing
├── mongodb/
│   └── init/
│       └── 01-init-collections.js # MongoDB collections and sample data
├── backups/                       # Database backups (created automatically)
├── check-connection.sh           # Database connection checker
├── backup-restore.sh             # Backup and restore utilities
└── README.md                     # This file
```

## 🚀 Quick Start

### 1. Start Databases

```bash
# Start all database services
docker-compose up -d postgres mongodb redis

# Check if databases are running
docker-compose ps
```

### 2. Check Database Connections

```bash
# Run the connection checker
./database/check-connection.sh
```

### 3. Verify Data

```bash
# Check PostgreSQL
docker exec -it kindledger-postgres psql -U kindledger -d kindledger -c "SELECT COUNT(*) FROM campaigns;"

# Check MongoDB
docker exec -it kindledger-mongodb mongosh --username kindledger --password kindledger123 --authenticationDatabase kindledger --eval "db.campaigns.countDocuments()"

# Check Redis
docker exec -it kindledger-redis redis-cli -a kindledger123 ping
```

## 📊 Database Schemas

### PostgreSQL Tables

| Table | Description |
|-------|-------------|
| `campaigns` | Campaign information and status |
| `donations` | Donation records and tracking |
| `users` | User accounts and authentication |
| `organizations` | Organization management |
| `transactions` | Blockchain transaction audit trail |

### MongoDB Collections

| Collection | Description |
|------------|-------------|
| `campaigns` | Campaign documents with metadata |
| `donations` | Donation documents with analytics |
| `users` | User profiles and preferences |
| `transactions` | Transaction documents with blockchain data |
| `organizations` | Organization documents and settings |

## 🔧 Configuration

### Environment Variables

The databases are configured through environment variables in `docker-compose.yml`:

```yaml
# PostgreSQL
SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/kindledger
SPRING_DATASOURCE_USERNAME: kindledger
SPRING_DATASOURCE_PASSWORD: kindledger123

# MongoDB
SPRING_DATA_MONGODB_URI: mongodb://kindledger:kindledger123@mongodb:27017/kindledger

# Redis
SPRING_REDIS_HOST: redis
SPRING_REDIS_PORT: 6379
SPRING_REDIS_PASSWORD: kindledger123
```

### Connection Details

| Database | Host | Port | Username | Password | Database |
|----------|------|------|----------|----------|----------|
| PostgreSQL | localhost | 5432 | kindledger | kindledger123 | kindledger |
| MongoDB | localhost | 27017 | kindledger | kindledger123 | kindledger |
| Redis | localhost | 6379 | - | kindledger123 | - |

## 💾 Backup and Restore

### Create Backup

```bash
# Backup all databases
./database/backup-restore.sh backup

# Backup specific database
./database/backup-restore.sh backup --postgres-only --backup-name daily-backup
```

### Restore from Backup

```bash
# Restore all databases
./database/backup-restore.sh restore --backup-name daily-backup

# Restore specific database
./database/backup-restore.sh restore --backup-name daily-backup --postgres-only
```

### List Backups

```bash
# List all available backups
./database/backup-restore.sh list
```

### Clean Old Backups

```bash
# Clean backups older than 7 days
./database/backup-restore.sh clean

# Clean backups older than 30 days
./database/backup-restore.sh clean 30
```

## 🔍 Monitoring and Maintenance

### Health Checks

The databases include health checks in Docker Compose:

- **PostgreSQL**: `pg_isready` command
- **MongoDB**: `mongosh` ping command
- **Redis**: `redis-cli ping` command

### Performance Monitoring

```bash
# PostgreSQL performance
docker exec -it kindledger-postgres psql -U kindledger -d kindledger -c "SELECT * FROM pg_stat_activity;"

# MongoDB performance
docker exec -it kindledger-mongodb mongosh --username kindledger --password kindledger123 --authenticationDatabase kindledger --eval "db.serverStatus()"

# Redis performance
docker exec -it kindledger-redis redis-cli -a kindledger123 info memory
```

### Logs

```bash
# View database logs
docker-compose logs postgres
docker-compose logs mongodb
docker-compose logs redis

# Follow logs in real-time
docker-compose logs -f postgres
```

## 🛠️ Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if containers are running: `docker-compose ps`
   - Check port conflicts: `netstat -tulpn | grep :5432`

2. **Authentication Failed**
   - Verify credentials in `docker-compose.yml`
   - Check if databases are initialized properly

3. **Permission Denied**
   - Ensure scripts are executable: `chmod +x *.sh`
   - Check file permissions in backup directory

### Reset Databases

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: This will delete all data)
docker volume rm kindledger_postgres_data kindledger_mongodb_data kindledger_redis_data

# Start services again
docker-compose up -d postgres mongodb redis
```

## 📈 Scaling and Production

### Production Considerations

1. **Security**
   - Change default passwords
   - Use environment variables for sensitive data
   - Enable SSL/TLS connections
   - Configure firewall rules

2. **Performance**
   - Tune database parameters
   - Configure connection pooling
   - Set up monitoring and alerting
   - Plan for horizontal scaling

3. **Backup Strategy**
   - Automated daily backups
   - Off-site backup storage
   - Test restore procedures
   - Document recovery processes

### High Availability

For production deployment, consider:

- PostgreSQL: Master-slave replication
- MongoDB: Replica sets
- Redis: Redis Cluster
- Load balancers for database access

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
