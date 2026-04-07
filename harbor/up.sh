#!/usr/bin/env bash
# Bring Harbor up: render compose + configs from harbor.yml, then start the stack.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f docker-compose.yml ]]; then
  echo "docker-compose.yml missing — running ./prepare from harbor.yml ..."
  ./prepare
fi

if docker compose version &>/dev/null; then
  exec docker compose up -d "$@"
else
  exec docker-compose up -d "$@"
fi
