# Harbor

[Harbor](https://github.com/goharbor/harbor) is a CNCF OSS registry: Docker/OCI images, RBAC, replication, and optional vulnerability scanning (Trivy).

This folder follows the **official online installer** flow: `harbor.yml` is the source of truth; `./prepare` renders `docker-compose.yml` plus everything under `common/config/`. Those generated files are gitignored so you always regenerate from YAML (peak reproducibility, minimal drift).

```
┌─────────────────┐     ./prepare      ┌──────────────────────┐
│   harbor.yml    │ ─────────────────► │ docker-compose.yml   │
│  (you edit)     │                    │ + common/config/...  │
└─────────────────┘                    └──────────┬───────────┘
                                                  │
                                                  ▼
                                       docker compose up -d
                                       (or ./up.sh)
```

| Artifact            | Role                                      |
| ------------------- | ----------------------------------------- |
| `harbor.yml`        | Hostname, HTTP/HTTPS, passwords, data paths |
| `./prepare`         | Runs `goharbor/prepare` (matches `_version`) |
| `docker-compose.yml` | Generated stack (ignored by Git)         |
| `./data/`           | Registry + DB + Redis state (ignored)     |

## Prerequisites

- Docker 20.10+ and **Docker Compose v2** (`docker compose`) on the **Linux** host where Harbor runs (Proxmox Docker host).
  `prepare` uses privileged chown on bind mounts; **Docker Desktop on macOS often fails** — run `./prepare` on the homelab machine.
- DNS or client `hosts` entry for `hostname` in `harbor.yml` (default `harbor.lan`).

## Setup

```bash
cd /path/to/homelab/harbor

# 1. Set secrets and network identity (see env.example for notes)
vim harbor.yml
# - hostname: FQDN or LAN name clients and k8s use to reach the registry
# - harbor_admin_password / database.password: change from placeholders

# 2. Render compose + nginx/registry configs
./prepare

# 3. Start (pulls images; online installer)
./up.sh
# or: ./install.sh
# or: docker compose up -d
```

Default UI and registry (HTTP, homelab-friendly port):

- **Portal**: `http://harbor.lan:8080` (user `admin`, password from `harbor_admin_password` until you change it in the UI)

## Optional: Trivy scanner

```bash
./prepare --with-trivy
docker compose down
docker compose up -d
```

(Or `./install.sh --with-trivy` on a fresh install.)

## Docker clients

Log in and push (insecure registry example — prefer HTTPS + real certs when you graduate from LAN HTTP):

```bash
docker login harbor.lan:8080
# docker tag myimage:latest harbor.lan:8080/library/myimage:latest
# docker push harbor.lan:8080/library/myimage:latest
```

For HTTP registries, Docker needs `insecure-registries` on the daemon; see [Harbor docs](https://goharbor.io/docs/).

## Version pin

`harbor.yml` ends with `_version: 2.15.0`, aligned with `goharbor/prepare:v2.15.0` in `./prepare`. Bump both together when upgrading Harbor.

## Upstream

- Installer scripts and `LICENSE` are from the [Harbor online installer release tarball](https://github.com/goharbor/harbor/releases) (Apache 2.0).
