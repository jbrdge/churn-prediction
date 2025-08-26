#!/usr/bin/env bash
set -euo pipefail

DB="${MYSQL_DB:-churn_project}"
USER="${MYSQL_USER:-churn}"
HOST="${MYSQL_HOST:-127.0.0.1}"
PORT="${MYSQL_PORT:-3306}"

CSV_PATH="${CSV_PATH:-$PWD/data/Telco-Customer-Churn.csv}"

echo "Loading CSV from: $CSV_PATH"
mysql --local-infile=1 -h "$HOST" -P "$PORT" -u "$USER" -p "$DB" -e "
  SET SESSION local_infile=1;
  LOAD DATA LOCAL INFILE '$CSV_PATH'
  INTO TABLE customers
  FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
  IGNORE 1 ROWS;
"
echo "Done."