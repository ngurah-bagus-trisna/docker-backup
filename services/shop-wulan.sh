#!/bin/bash
set -e

COMPOSE="$COMPOSE_BASE/shop-wulan/docker-compose.yml"

log "dump mariadb (shop-wulan)"

compose_exec "$COMPOSE" db \
  mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" \
  --single-transaction --quick --lock-tables=false \
  > "$TMP_DIR/shop-wulan.sql"

log "copy wordpress volume"
copy_volume shop-wulan_wordpress_data wordpress
