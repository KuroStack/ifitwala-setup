#!/bin/bash
# Clones ifitwala_ed_v2 and brings up the full Docker stack on a fresh machine.
#
# Usage:
#   ./setup.sh                # clone + build + start
#   ./setup.sh --no-start     # clone + build only
#   ./setup.sh --rebuild      # re-clone (pull latest) + rebuild image + restart
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

REPO_DIR="repo/ifitwala_ed"
START=1
REBUILD=0

for arg in "$@"; do
  case "${arg}" in
    --no-start) START=0 ;;
    --rebuild) REBUILD=1 ;;
    *) echo "Unknown option: ${arg}" && exit 1 ;;
  esac
done

echo "==> Checking prerequisites"
for cmd in git docker; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but not installed." >&2
    exit 1
  fi
done

if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "Error: docker compose (v2 plugin or docker-compose) is required." >&2
  exit 1
fi

if [ ! -f .env ]; then
  echo "==> Creating .env from .env.example"
  cp .env.example .env
fi

# shellcheck disable=SC1091
set -a
source .env
set +a

IFITWALA_ED_REPO="${IFITWALA_ED_REPO:-https://github.com/fderyckel/ifitwala_ed_v2.git}"
IFITWALA_ED_BRANCH="${IFITWALA_ED_BRANCH:-main}"

echo "==> Fetching ifitwala_ed source (${IFITWALA_ED_REPO}@${IFITWALA_ED_BRANCH})"
mkdir -p repo
if [ -d "${REPO_DIR}/.git" ]; then
  if [ "${REBUILD}" -eq 1 ]; then
    git -C "${REPO_DIR}" fetch origin "${IFITWALA_ED_BRANCH}"
    git -C "${REPO_DIR}" checkout "${IFITWALA_ED_BRANCH}"
    git -C "${REPO_DIR}" reset --hard "origin/${IFITWALA_ED_BRANCH}"
  else
    echo "    ${REPO_DIR} already exists, skipping clone (use --rebuild to update)."
  fi
else
  git clone --branch "${IFITWALA_ED_BRANCH}" --depth 1 "${IFITWALA_ED_REPO}" "${REPO_DIR}"
fi

echo "==> Building Docker image"
if [ "${REBUILD}" -eq 1 ]; then
  ${COMPOSE} build --no-cache backend
else
  ${COMPOSE} build backend
fi

if [ "${START}" -eq 1 ]; then
  echo "==> Starting stack"
  ${COMPOSE} up -d

  echo ""
  echo "Setup complete."
  echo "  Site:  http://localhost:${HTTP_PORT:-8000}"
  echo "  User:  Administrator"
  echo "  Pass:  ${ADMIN_PASSWORD:-admin}"
  echo ""
  echo "First boot creates the site and installs apps; this can take a few minutes."
  echo "Follow logs with: ${COMPOSE} logs -f backend"
else
  echo "==> Skipping stack start (--no-start given). Run '${COMPOSE} up -d' when ready."
fi
