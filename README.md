# ifitwala_ed Docker Setup

Minimal, standalone Docker setup for [ifitwala_ed_v2](https://github.com/fderyckel/ifitwala_ed_v2).
This repo contains no application source — `setup.sh` clones it fresh on whatever
machine you run it on, then builds and starts the full stack.

## Prerequisites

- Docker with the Compose v2 plugin (`docker compose`), or standalone `docker-compose`
- `git`

## Quick start

```bash
git clone <this-repo-url> ifitwala_ed_docker
cd ifitwala_ed_docker
./setup.sh
```

This will:
1. Create `.env` from `.env.example` (edit it first if you want non-default ports/passwords).
2. Clone `ifitwala_ed_v2` into `repo/ifitwala_ed`.
3. Build the custom Frappe image (bundling `frappe`, `ifitwala_drive`, and `ifitwala_ed`).
4. Start the full stack with `docker compose up -d`.

On first boot, the `backend` container creates the site and installs both apps
automatically — this takes a few minutes. Then visit http://localhost:8000
(`Administrator` / the password in `.env`, default `admin`).

## Updating

```bash
./setup.sh --rebuild
```

Pulls the latest `ifitwala_ed_v2` from the configured branch, rebuilds the image
without cache, and restarts the stack.

## Other options

```bash
./setup.sh --no-start   # clone + build only, don't start containers
```

## What's in this repo

| Path                    | Purpose                                              |
|--------------------------|-------------------------------------------------------|
| `setup.sh`               | Clones the app repo and drives build/start            |
| `docker/Dockerfile`      | Multi-stage Frappe image build (bench init + apps)     |
| `docker/entrypoint.sh`   | First-boot site creation, app install, config sync     |
| `docker-compose.yml`     | MariaDB, Redis, backend, websocket, workers, scheduler |
| `.env.example`           | Config template (ports, passwords, source repo/branch) |

`repo/` (the cloned app source) and `.env` are gitignored — they're generated locally.

## Services

| Service       | Purpose                                   |
|---------------|--------------------------------------------|
| mariadb       | Database                                    |
| redis-cache   | Frappe cache                                |
| redis-queue   | Background job / pub-sub queue              |
| backend       | Gunicorn web server (bench start)           |
| websocket     | Realtime (socket.io) server                 |
| queue-short   | Background worker, short/default queue      |
| queue-long    | Background worker, long/default queue       |
| scheduler     | Cron-like scheduled jobs (bench schedule)   |

## Notes

- `ifitwala_drive` (a hard dependency of `ifitwala_ed`) is pulled directly from
  `https://github.com/fderyckel/ifitwala_drive` (branch `main`) during the image build.
- Rebuild the image after any source change (`./setup.sh --rebuild` or
  `docker compose build backend`) — the Dockerfile copies a snapshot of `repo/ifitwala_ed`
  at build time rather than mounting it live.
- Data persists in the `mariadb-data` and `sites` named volumes across restarts.
  Remove them (`docker compose down -v`) for a clean slate.
