#!/usr/bin/env bash
# Build NixOS VM image locally
# Usage: ./scripts/build-vm-image-local.sh [linux-host]
# If linux-host is provided, builds remotely via SSH
# Otherwise, attempts local build (requires Linux)

set -euo pipefail

cd "$(dirname "$0")/../nix"

if [ $# -eq 1 ]; then
  # Remote build via SSH
  REMOTE_HOST="$1"
  echo "Building VM image on remote host: $REMOTE_HOST"

  # Copy flake to remote host
  rsync -avz --exclude='.git' --exclude='result*' ./ "$REMOTE_HOST:~/homelab-build/nix/"

  # Build on remote
  ssh "$REMOTE_HOST" "cd ~/homelab-build/nix && nix run github:nix-community/nixos-generators -- --format raw --flake '.#template' -o result"

  # Copy result back
  scp "$REMOTE_HOST:~/homelab-build/nix/result/nixos.raw" ./nixos-template.raw

  echo "✅ Image built: nixos-template.raw"
  echo "Convert to qcow2: qemu-img convert -f raw -O qcow2 nixos-template.raw nixos-template.qcow2"
else
  # Local build (requires Linux)
  echo "Building VM image locally..."
  nix run github:nix-community/nixos-generators -- \
    --format raw \
    --flake '.#template' \
    -o result

  if [ -f result/nixos.raw ]; then
    cp result/nixos.raw ./nixos-template.raw
    echo "✅ Image built: nixos-template.raw"
    echo "Convert to qcow2: qemu-img convert -f raw -O qcow2 nixos-template.raw nixos-template.qcow2"
  else
    echo "❌ Error: Could not find result/nixos.raw"
    ls -la result/
    exit 1
  fi
fi
