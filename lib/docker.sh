#!/bin/bash
# lib/docker.sh

# Track project yang sudah diproses biar gak sinkronisasi ulang di folder yang sama
PROCESSED_PROJECTS=""

list_backup_containers() {
  docker ps -q | xargs -r docker inspect | jq -r '
    .[] | select(.Config.Labels["backup.enable"]=="true") | .Id
  '
}

get_container_info() {
  local cid="$1"
  local query="$2"
  docker inspect "$cid" | jq -r "$query"
}

# --- Backup Logic ---

backup_project_folder() {
  local cid="$1"
  local name="$2"
  local work_dir
  work_dir=$(get_container_info "$cid" '.[0].Config.Labels["com.docker.compose.project.working_dir"]')

  # Validasi: Folder ada dan belum pernah diproses dalam session ini
  if [ "$work_dir" != "null" ] && [ -d "$work_dir" ]; then
    if [[ ! "$PROCESSED_PROJECTS" =~ "$work_dir" ]]; then
      log "📁 [Project] Syncing project directory: $work_dir"
      
      local project_name
      project_name=$(basename "$work_dir")
      local dst="${TMP_DIR}/projects/${project_name}"
      
      mkdir -p "$dst"
      
      # Sync semua file config, .env, certs, dll.
      # --delete memastikan file yang dihapus di src juga hilang di backup staging
      rsync -aHAX --delete \
        --exclude 'node_modules' \
        --exclude '.git' \
        --exclude 'logs' \
        "$work_dir/" "$dst/"

      # Tandai project sudah di-backup
      PROCESSED_PROJECTS+="$work_dir "
    else
      log "⏭️ [Project] $work_dir already synced, skipping..."
    fi
  fi
}

copy_named_volume() {
  local volume="$1"
  local src="/var/lib/docker/volumes/${volume}/_data"
  local dst="${TMP_DIR}/volumes/${volume}"

  if [ -d "$src" ]; then
    log "📦 [Volume] Syncing named volume: $volume"
    mkdir -p "$dst"
    rsync -aHAX --delete --numeric-ids "$src/" "$dst/"
  fi
}

dump_mysql() {
  local cid="$1"
  local name="$2"
  local dst="${TMP_DIR}/db/${name}"
  mkdir -p "$dst"
  log "🛢️ [MySQL] Dumping database for $name"
  
  docker exec -T "$cid" sh -c 'mysqldump -u"${MYSQL_USER:-root}" -p"${MYSQL_PASSWORD:-$MYSQL_ROOT_PASSWORD}" --all-databases' > "$dst/dump.sql"
}

dump_postgres() {
  local cid="$1"
  local name="$2"
  local dst="${TMP_DIR}/db/${name}"
  mkdir -p "$dst"
  log "🐘 [Postgres] Dumping database for $name"
  
  docker exec -T "$cid" sh -c 'pg_dumpall -U "${POSTGRES_USER:-postgres}"' > "$dst/dump.sql"
}

# --- Decision Engine ---

backup_container() {
  local cid="$1"
  local name
  name=$(get_container_info "$cid" '.[0].Name' | sed 's|/||')
  local type
  type=$(get_container_info "$cid" '.[0].Config.Labels["backup.type"] // "volume"')

  log "🚀 Processing: $name"

  # 1. Backup Folder Project (Sangat penting buat Traefik/Bind Mounts)
  backup_project_folder "$cid" "$name"

  # 2. Backup Metadata Inspect (Buat jaga-jaga kalau butuh spek container di server baru)
  local meta_dst="${TMP_DIR}/metadata/${name}"
  mkdir -p "$meta_dst"
  docker inspect "$cid" > "$meta_dst/inspect.json"

  # 3. Backup Data Spesifik berdasarkan tipe
  case "$type" in
    volume)
      # Cari Named Volumes saja. Bind Mounts sudah ter-cover oleh fungsi backup_project_folder di atas.
      docker inspect "$cid" | jq -r '.[0].Mounts[] | select(.Type=="volume") | .Name' | while read -r v; do
        copy_named_volume "$v"
      done
      ;;
    mysql|mariadb)
      dump_mysql "$cid" "$name"
      ;;
    postgres)
      dump_postgres "$cid" "$name"
      ;;
    *)
      log "⚠️ Unknown backup.type: $type, data backup handled by project sync if using bind mounts."
      ;;
  esac
}