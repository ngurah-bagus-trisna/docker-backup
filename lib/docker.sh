#!/bin/bash

# exec command inside service
compose_exec() {
  local compose_file="$1"
  local service="$2"
  shift 2

  docker compose -f "$compose_file" exec -T "$service" "$@"
}

# check service running
compose_service_running() {
  local compose_file="$1"
  local service="$2"

  docker compose -f "$compose_file" ps "$service" \
    --status running | grep -q "$service"
}

# copy docker volume data to temp dir
# usage: copy_volume volume_name target_subdir
copy_volume() {
  local volume="$1"
  local target="$2"

  local src="/var/lib/docker/volumes/${volume}/_data"
  local dst="${TMP_DIR}/${target}"

  if [ ! -d "$src" ]; then
    echo "⚠️ volume not found: $volume"
    return 0
  fi

  mkdir -p "$dst"
  rsync -a --delete "$src/" "$dst/"
}
