#!/bin/bash
set -e

if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

DB_ARGS=()

function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d " " -f3 | sed 's/["\n\r]//g')
    fi
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}

# Variables de entorno
: ${HOST:=${DB_HOST}}
: ${DBPORT:=${DB_PORT:=5432}}
: ${USER:=${DB_USER}}
: ${PASSWORD:=${DB_PASSWORD}}
: ${DBNAME:=${DB_NAME:=odoo}}

# Forzar SSL para Neon
export PGSSLMODE=require
export PGPASSWORD="${PASSWORD}"

# Construir args
check_config "db_host" "$HOST"
check_config "db_port" "$DBPORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

echo "==> Waiting for Postgres..."
wait-for-psql.py ${DB_ARGS[@]} --timeout=30

echo "==> Initializing database '${DBNAME}' (installing base)..."
# NOTA: no usamos exec aquí para poder arrancar Odoo después de la init
odoo "${DB_ARGS[@]}" -d "${DBNAME}" -i base --stop-after-init

echo "==> Initialization finished. Starting Odoo normally..."
exec odoo "$@" "${DB_ARGS[@]}"
