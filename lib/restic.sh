#!/bin/bash
# lib/restic.sh

restic_init() {
  if ! restic snapshots >/dev/null 2>&1; then
    log "init restic repository..."
    restic init
  fi
}

restic_run() {
  log "📤 Pushing to Restic repository..."
  restic backup "$TMP_DIR" --tag "docker-auto-backup"
}

restic_prune() {
  log "🧹 Pruning old snapshots..."
  restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune
}