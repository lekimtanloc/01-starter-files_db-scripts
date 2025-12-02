#!/bin/bash
set -e

# ---- Config ----
DB_HOST=${DB_HOST:-"mariadb"}
DB_PORT=${DB_PORT:-3306}
DB_USERNAME=${DB_USERNAME:-"root"}
DB_PASSWORD=${DB_PASSWORD:-"root"}
DB_NAME=${DB_NAME:-"app_db"}
SQL_DIR=${SQL_DIR:-"/init/sql"}
MAX_RETRIES=${MAX_RETRIES:-30}

RETRY_COUNT=0

# Thêm biến chung cho option MySQL (tắt SSL)
MYSQL_BASE_CMD=(
  mysql
  -h"$DB_HOST"
  -P"$DB_PORT"
  -u"$DB_USERNAME"
  -p"$DB_PASSWORD"
  --protocol=TCP
  --ssl=0         # <--- QUAN TRỌNG: tắt SSL
)

echo "--------------------------------------"
echo "Waiting for MySQL to be ready..."
echo "Host: $DB_HOST  Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "--------------------------------------"

# ---- Wait for MySQL ----
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "Attempting to connect to MySQL at $DB_HOST (try $((RETRY_COUNT + 1))/$MAX_RETRIES)..."

  if "${MYSQL_BASE_CMD[@]}" --connect-timeout=5 -e "SELECT 1;" &>/dev/null; then
    echo "Success: MySQL is up and running!"
    break
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "MySQL unavailable, sleeping (attempt $RETRY_COUNT/$MAX_RETRIES)..."
  sleep 3
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
  echo "Error: Failed to connect to MySQL after $MAX_RETRIES attempts."
  exit 1
fi

# ---- Import SQL files ----
if [ -d "$SQL_DIR" ]; then
  echo "Starting import of SQL files from directory: $SQL_DIR"
  for sql_file in "$SQL_DIR"/*.sql; do
    [ -f "$sql_file" ] || continue
    echo "Importing $sql_file ..."
    "${MYSQL_BASE_CMD[@]}" --connect-timeout=10 "$DB_NAME" < "$sql_file"
  done
  echo "Success: All SQL files imported successfully."
else
  echo "Directory $SQL_DIR not found, skipping import."
fi
