BACKUP_DIR=~/backups/mining-ops-$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
cd ~/Mining-ops-Data-Entry-Platform

# 1. Project files (excluding .git and __pycache__)
tar --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
    -czf "$BACKUP_DIR/project-files.tar.gz" .

# 2. PostgreSQL full dump (user: mining, db: mining_db)
docker compose exec -T db pg_dump -U mining mining_db > "$BACKUP_DIR/db_dump.sql"

# 3. Named volume: postgres_data
docker run --rm \
  -v mining-ops-data-entry-platform_postgres_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar -czf /backup/volume-postgres_data.tar.gz -C /data .

echo "✅ Done"
ls -lh "$BACKUP_DIR"


####################


# 1. Restore project files
mkdir -p ~/Mining-ops-Data-Entry-Platform
tar -xzf project-files.tar.gz -C ~/Mining-ops-Data-Entry-Platform

# 2. Start the DB first
cd ~/Mining-ops-Data-Entry-Platform
docker compose up -d db && sleep 5

# 3. Restore the SQL dump
docker compose exec -T db psql -U mining mining_db < db_dump.sql

# 4. Bring up everything
docker compose up -d
