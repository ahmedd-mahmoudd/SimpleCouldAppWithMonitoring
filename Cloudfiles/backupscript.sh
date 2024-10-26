#!/bin/bash

# Variables
DB_PATH="tasks.db"
BACKUP_DIR="backup" 
DATE=$(date +%Y%m%d)                   
BACKUP_FILE="$BACKUP_DIR/sqlite_backup_$DATE.db"

# Create a backup by copying the SQLite database file
echo "Backing up SQLite database..."
cp $DB_PATH $BACKUP_FILE
gzip $BACKUP_FILE

# Confirm backup success
if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_FILE.gz"
else
    echo "Backup failed!" >&2
    exit 1
fi

