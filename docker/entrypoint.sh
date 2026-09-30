#!/bin/bash
set -e

cd /home/frappe/frappe-bench

: "${SITE_NAME:=ifitwala.localhost}"
: "${DB_HOST:=mariadb}"
: "${DB_PORT:=3306}"
: "${REDIS_CACHE:=redis://redis-cache:6379}"
: "${REDIS_QUEUE:=redis://redis-queue:6379}"
: "${ADMIN_PASSWORD:=admin}"
: "${DB_ROOT_PASSWORD:=admin}"

wait_for() {
  local host="$1"
  local port="$2"
  echo "Waiting for ${host}:${port}..."
  until (echo > "/dev/tcp/${host}/${port}") >/dev/null 2>&1; do
    sleep 2
  done
  echo "${host}:${port} is up."
}

wait_for "${DB_HOST}" "${DB_PORT}"
wait_for "$(echo "${REDIS_CACHE}" | sed -E 's#redis://##; s#:.*##')" "$(echo "${REDIS_CACHE}" | sed -E 's#.*:##')"

LOCK_FILE="sites/.site_setup.lock"
DONE_FILE="sites/.site_setup.done"

if [ ! -f "${DONE_FILE}" ]; then
  if mkdir "${LOCK_FILE}" 2>/dev/null; then
    if [ ! -d "sites/${SITE_NAME}" ]; then
      echo "Site ${SITE_NAME} not found. Creating it..."
      bench new-site "${SITE_NAME}" \
        --db-host "${DB_HOST}" \
        --db-port "${DB_PORT}" \
        --mariadb-root-password "${DB_ROOT_PASSWORD}" \
        --admin-password "${ADMIN_PASSWORD}" \
        --no-mariadb-socket

      bench --site "${SITE_NAME}" install-app ifitwala_drive
      bench --site "${SITE_NAME}" install-app ifitwala_ed
      bench --site "${SITE_NAME}" set-config developer_mode 0
      bench use "${SITE_NAME}"
    fi
    touch "${DONE_FILE}"
    rmdir "${LOCK_FILE}"
  else
    echo "Another container is already setting up the site. Waiting..."
    while [ ! -f "${DONE_FILE}" ]; do
      sleep 2
    done
  fi
fi

bench set-config -g redis_cache "${REDIS_CACHE}"
bench set-config -g redis_queue "${REDIS_QUEUE}"
bench set-config -g redis_socketio "${REDIS_QUEUE}"
bench set-config -g db_host "${DB_HOST}"
bench set-config -g db_port "${DB_PORT}"

exec "$@"
