#!/usr/bin/env bash
set -euo pipefail
node scripts/migrate.js
mysql -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" -u "${DB_USER:-root}" -p"${DB_PASSWORD:-}" "${DB_NAME:-pm_tracker}" < db/migrations/002_customers_terms_and_backlog.sql
echo "Applied 002_customers_terms_and_backlog.sql"
