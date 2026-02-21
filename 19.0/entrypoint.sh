#!/bin/bash
set -e

# Variables de entorno
: ${HOST:=${DB_HOST}}
: ${DBPORT:=${DB_PORT:=5432}}
: ${USER:=${DB_USER}}
: ${PASSWORD:=${DB_PASSWORD}}

export PGSSLMODE=require

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

check_config "db_host" "$HOST"
check_config "db_port" "$DBPORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"
DB_ARGS+=("--database" "${DB_NAME}")

# Lanzar Odoo
exec wait-for-psql.py ${DB_ARGS[@]} --timeout=30 && exec odoo "$@" "${DB_ARGS[@]}"
