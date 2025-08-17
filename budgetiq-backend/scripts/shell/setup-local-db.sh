#!/usr/bin/env bash
set -euo pipefail

PGHOST="${PG_HOST:-localhost}"
PGPORT="${PG_PORT:-5432}"

echo "▶️  Bootstrapping local Postgres on ${PGHOST}:${PGPORT}"

# choose a working psql invocation (current OS user, env admin, postgres)
try_psql() {
  # 1) no -U (macOS user is often superuser on Postgres.app)
  psql -h "$PGHOST" -p "$PGPORT" -d tusharnagdive -v ON_ERROR_STOP=1 -c "select 1" && { echo "• using local OS user"; return 0; }

  # 2) env-provided admin
  if [[ -n "${PG_ADMIN_USER:-}" ]]; then
    PGPASSWORD="${PG_ADMIN_PASSWORD:-}" psql -h "$PGHOST" -p "$PGPORT" -U "$PG_ADMIN_USER" -d tusharnagdive -v ON_ERROR_STOP=1 -c "select 1" \
      && { echo "• using \$PG_ADMIN_USER=$PG_ADMIN_USER"; return 0; }
  fi

  # 3) fallback to postgres role
  psql -h "$PGHOST" -p "$PGPORT" -U tusharnagdive -d tusharnagdive -v ON_ERROR_STOP=1 -c "select 1" && { echo "• using postgres user"; return 0; }

  echo "❌ Unable to connect to Postgres. Set PG_ADMIN_USER/PG_ADMIN_PASSWORD or start Postgres."
  exit 2
}

# run a SQL command with whichever method worked in try_psql()
run_sql() {
  if psql -h "$PGHOST" -p "$PGPORT" -d tusharnagdive -v ON_ERROR_STOP=1 -c "select 1" >/dev/null 2>&1; then
    psql -h "$PGHOST" -p "$PGPORT" -d tusharnagdive -v ON_ERROR_STOP=1 -c "$1"
    return
  fi
  if [[ -n "${PG_ADMIN_USER:-}" ]]; then
    PGPASSWORD="${PG_ADMIN_PASSWORD:-}" psql -h "$PGHOST" -p "$PGPORT" -U "$PG_ADMIN_USER" -d tusharnagdive -v ON_ERROR_STOP=1 -c "$1"
    return
  fi
  psql -h "$PGHOST" -p "$PGPORT" -U tusharnagdive -d tusharnagdive -v ON_ERROR_STOP=1 -c "$1"
}

# run a SQL command against a specific DB (used for extensions)
run_sql_db() {
  local db="$1"
  local sql="$2"
  if psql -h "$PGHOST" -p "$PGPORT" -d "$db" -v ON_ERROR_STOP=1 -c "select 1" >/dev/null 2>&1; then
    psql -h "$PGHOST" -p "$PGPORT" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
    return
  fi
  if [[ -n "${PG_ADMIN_USER:-}" ]]; then
    PGPASSWORD="${PG_ADMIN_PASSWORD:-}" psql -h "$PGHOST" -p "$PGPORT" -U "$PG_ADMIN_USER" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
    return
  fi
  psql -h "$PGHOST" -p "$PGPORT" -U tusharnagdive -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
}

# ensure server is reachable
if command -v pg_isready >/dev/null 2>&1; then
  pg_isready -h "$PGHOST" -p "$PGPORT" >/dev/null || { echo "❌ Postgres not ready on ${PGHOST}:${PGPORT}"; exit 2; }
fi

try_psql

# 1) role
ROLE_EXISTS=$(psql -h "$PGHOST" -p "$PGPORT" -d tusharnagdive -tAc "select 1 from pg_roles where rolname='budgetiq'" || echo "")
if [[ "$ROLE_EXISTS" != "1" ]]; then
  echo "• creating role budgetiq"
  run_sql "CREATE ROLE budgetiq WITH LOGIN PASSWORD 'budgetiq';"
  run_sql "ALTER ROLE budgetiq CREATEDB;"
else
  echo "• role budgetiq already exists"
fi

# 2) database
DB_EXISTS=$(psql -h "$PGHOST" -p "$PGPORT" -d tusharnagdive -tAc "select 1 from pg_database where datname='budgetiq'" || echo "")
if [[ "$DB_EXISTS" != "1" ]]; then
  echo "• creating database budgetiq"
  run_sql "CREATE DATABASE budgetiq OWNER budgetiq;"
else
  echo "• database budgetiq already exists"
fi

# 3) grants (safe to repeat)
echo "• granting privileges"
run_sql "GRANT ALL PRIVILEGES ON DATABASE budgetiq TO budgetiq;"

# 4) useful extensions inside target DB (safe to repeat)
echo "• ensuring extensions in budgetiq"
run_sql_db "budgetiq" "CREATE EXTENSION IF NOT EXISTS citext;"
run_sql_db "budgetiq" "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

echo "✅ DB bootstrap complete."
