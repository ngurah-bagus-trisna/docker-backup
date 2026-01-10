#!/bin/bash
# backup.sh
set -euo pipefail

# Ambil path absolut script
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/config.sh"
source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/docker.sh"
source "$BASE_DIR/lib/restic.sh"

log "--- BACKUP STARTED ---"

# 1. Persiapan Restic
restic_init

# 2. Iterasi Container
list_backup_containers | while read -r cid; do
  backup_container "$cid"
done

# 3. Eksekusi Backup & Cleanup
restic_run
restic_prune

# Hapus staging area agar tidak makan space lokal
rm -rf "${TMP_DIR:?}"/*

log "--- BACKUP FINISHED SUCCESSFULLY ---"