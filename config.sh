#!/bin/bash
# config.sh

# Path lokal untuk staging sebelum dikirim ke Restic
BACKUP_ROOT="/backup"
TMP_DIR="$BACKUP_ROOT/tmp"
LOG_DIR="$BACKUP_ROOT/logs"

# Restic Config
export RESTIC_REPOSITORY="$BACKUP_ROOT/restic"
export RESTIC_PASSWORD_FILE="/etc/restic.pass"

# Buat directory jika belum ada
mkdir -p "$TMP_DIR" "$LOG_DIR" "$RESTIC_REPOSITORY"