#!/bin/bash
# restore.sh - Disaster Recovery Entrypoint
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load configuration and helpers
source "$BASE_DIR/config.sh"
source "$BASE_DIR/lib/utils.sh"

# 1. Dependency & Mount Check
log "🔍 Checking environment..."
require restic
require jq

if [ ! -d "$RESTIC_REPOSITORY" ]; then
    log "❌ Error: Restic repository not found at $RESTIC_REPOSITORY"
    log "👉 Make sure your Rclone/GDrive is mounted before running this."
    exit 1
fi

# 2. List Snapshots
log "📂 Fetching available snapshots from repository..."
restic snapshots

echo "--------------------------------------------------------"
read -p "Enter Snapshot ID to restore (or 'latest'): " SNAP_ID
read -p "Enter Absolute Path for restore destination (e.g., /home/bagus/restore): " TARGET_PATH
echo "--------------------------------------------------------"

mkdir -p "$TARGET_PATH"

# 3. Execution
log "⏳ Restoring snapshot [$SNAP_ID] to [$TARGET_PATH]..."

# We restore everything from the snapshot
if restic restore "$SNAP_ID" --target "$TARGET_PATH"; then
    log "✅ Files restored successfully to: $TARGET_PATH"
else
    log "❌ Restore failed. Check your Restic password or repository connection."
    exit 1
fi

# 4. Post-Restore Summary
log "📋 Post-Restore Instructions for $SNAP_ID:"
echo "--------------------------------------------------------"
echo "Your data is now organized in: $TARGET_PATH/backup/tmp/"
echo ""
echo "1. PROJECTS: Copy folders from 'projects/' to your production path."
echo "   Example: cp -r $TARGET_PATH/backup/tmp/projects/traefik /opt/traefik"
echo ""
echo "2. DATABASES: Re-import SQL dumps found in 'db/'."
echo "   Example: docker exec -i <container_name> mysql -u root -p < dump.sql"
echo ""
echo "3. METADATA: Check 'metadata/' if you forgot environment variables."
echo "--------------------------------------------------------"