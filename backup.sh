#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# load config
source "$BASE_DIR/config.env"

# load libs
source "$BASE_DIR/lib/common.sh"
source "$BASE_DIR/lib/log.sh"
source "$BASE_DIR/lib/docker.sh"

common_init

mkdir -p "$TMP_DIR" "$LOG_DIR"

LOG="$LOG_DIR/backup-$(date +%F).log"
exec >> "$LOG" 2>&1

log_section "INFRA BACKUP START"
log "time: $(date)"

# =========================
# RUN SERVICE BACKUPS
# =========================
for svc in "$BASE_DIR/services/"*.sh; do
  log_section "RUN $(basename "$svc")"
  source "$svc"
done

# =========================
# RESTIC SNAPSHOT
# =========================
log_section "RESTIC BACKUP"

restic backup \
  "$COMPOSE_BASE" \
  /var/lib/docker/volumes \
  "$TMP_DIR" \
  --tag infra,full

# =========================
# RETENTION
# =========================
log_section "RESTIC PRUNE"

restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --prune

# =========================
# CLEANUP
# =========================
rm -rf "$TMP_DIR"/*

log_section "BACKUP FINISHED"
log "done at $(date)"
