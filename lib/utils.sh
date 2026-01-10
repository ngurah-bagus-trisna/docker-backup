#!/bin/bash
# lib/utils.sh

log() {
  echo "[$(date '+%F %T')] $*"
}

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing command: $1. Please install it first."
    exit 1
  }
}

# Cek dependencies
require docker
require jq
require rsync
require restic