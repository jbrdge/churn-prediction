#!/usr/bin/env bash
set -euo pipefail

# Load .env (export all keys)
if [[ ! -f .env ]]; then
  echo ".env not found in $(pwd). Create it from .env.example."
  exit 1
fi

set -a
source .env
set +a

# Quick sanity print (safe fields only)
echo "Env loaded:"
echo "  MYSQL_HOST=${MYSQL_HOST:-unset}"
echo "  MYSQL_PORT=${MYSQL_PORT:-unset}"
echo "  MYSQL_DB=${MYSQL_DB:-unset}"
echo "  MYSQL_USER is set: $([[ -n ${MYSQL_USER:-} ]] && echo yes || echo no)"
echo "  MYSQL_PASSWORD is set: $([[ -n ${MYSQL_PASSWORD:-} ]] && echo yes || echo no)"
