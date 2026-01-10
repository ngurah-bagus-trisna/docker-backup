#!/bin/bash

log() {
  echo "[$(date '+%F %T')] $*"
}

log_section() {
  echo
  echo "===== $* ====="
}
