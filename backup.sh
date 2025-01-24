#!/bin/bash
# Backup Script
BACKUP_DIR=$1
DESTINATION=$2
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
LOGFILE="backup_log_$TIMESTAMP.txt"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Directory $BACKUP_DIR does not exist. Exiting." | tee -a "$LOGFILE"
    exit 1
fi

mkdir -p "$DESTINATION"
tar -czf "$DESTINATION/backup_$TIMESTAMP.tar.gz" "$BACKUP_DIR" 2>>"$LOGFILE"

if [ $? -eq 0 ]; then
    echo "Backup successful! File saved to $DESTINATION/backup_$TIMESTAMP.tar.gz" | tee -a "$LOGFILE"
    echo "Backup size: $(du -sh "$DESTINATION/backup_$TIMESTAMP.tar.gz" | cut -f1)" | tee -a "$LOGFILE"
else
    echo "Backup failed. Check logs for details." | tee -a "$LOGFILE"
fi
