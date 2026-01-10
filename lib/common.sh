#!/bin/bash

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ command not found: $1"
    exit 1
  }
}

require_env() {
  local var="$1"
  if [ -z "${!var:-}" ]; then
    echo "❌ env var $var is not set"
    exit 1
  fi
}

common_init() {
  require_cmd docker
  require_cmd restic

  require_env RESTIC_REPOSITORY
  require_env RESTIC_PASSWORD
  require_env COMPOSE_BASE
  require_env TMP_DIR

  mkdir -p "$TMP_DIR"
}
