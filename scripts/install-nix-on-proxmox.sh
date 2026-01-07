#!/usr/bin/env bash
# Install Nix on Proxmox host and build VM image
# Usage: ./scripts/install-nix-on-proxmox.sh [proxmox-host]

set -euo pipefail

PROXMOX_HOST="${1:-root@192.168.68.251}"

echo "🚀 Installing Nix on Proxmox host: $PROXMOX_HOST"
echo ""

# Install Nix via the official installer
ssh "$PROXMOX_HOST" << 'EOF'
  # Install Nix if not already installed
  if ! command -v nix &> /dev/null; then
    echo "Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --daemon --yes

    # Source nix-daemon.sh for current session
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    # Enable flakes
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

    echo "✅ Nix installed!"
  else
    echo "✅ Nix already installed"
    nix --version
  fi
EOF

echo ""
echo "📦 Building VM image on Proxmox host..."
echo ""

# Copy the nix directory to Proxmox host
ssh "$PROXMOX_HOST" "mkdir -p ~/homelab-build"
rsync -avz --exclude='.git' --exclude='result*' ./nix/ "$PROXMOX_HOST:~/homelab-build/nix/"

# Build the image
ssh "$PROXMOX_HOST" << 'EOF'
  cd ~/homelab-build/nix

  # Source nix if needed
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  echo "Building VM image..."
  nix run github:nix-community/nixos-generators -- \
    --format raw \
    --flake '.#template' \
    -o result

  # Convert to qcow2
  if [ -f result/nixos.raw ]; then
    echo "Converting to qcow2..."
    qemu-img convert -f raw -O qcow2 result/nixos.raw nixos-template.qcow2
    ls -lh nixos-template.qcow2
    echo "✅ Image built: ~/homelab-build/nix/nixos-template.qcow2"
  else
    echo "❌ Error: Could not find result/nixos.raw"
    ls -la result/
    exit 1
  fi
EOF

echo ""
echo "✅ Build complete!"
echo ""
echo "Next steps:"
echo "1. Download the image: scp $PROXMOX_HOST:~/homelab-build/nix/nixos-template.qcow2 ./"
echo "2. Upload to Proxmox storage"
echo "3. Create VM from image and convert to template"
