#!/usr/bin/env bash
# Install Nix on Proxmox host and build VM image
# Usage: ./scripts/install-nix-on-proxmox.sh [proxmox-host]

set -euo pipefail

PROXMOX_HOST="${1:-root@192.168.68.251}"

echo "🚀 Installing Nix on Proxmox host: $PROXMOX_HOST"
echo ""

# Install Nix via the official installer
ssh "$PROXMOX_HOST" << 'EOF'
  set -euo pipefail

  # Check if Nix is actually installed (not just in PATH)
  NIX_INSTALLED=false
  if [ -d /nix ] && [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    NIX_INSTALLED=true
  fi

  if [ "$NIX_INSTALLED" = false ]; then
    echo "Cleaning up any previous Nix installation artifacts..."

    # Remove backup files that might block installation
    if [ -f /etc/bash.bashrc.backup-before-nix ]; then
      echo "Removing old backup file..."
      rm -f /etc/bash.bashrc.backup-before-nix
    fi
    if [ -f /etc/bashrc.backup-before-nix ]; then
      rm -f /etc/bashrc.backup-before-nix
    fi
    if [ -f /etc/zshrc.backup-before-nix ]; then
      rm -f /etc/zshrc.backup-before-nix
    fi
    if [ -f /etc/zsh/zshrc.backup-before-nix ]; then
      rm -f /etc/zsh/zshrc.backup-before-nix
    fi

    # Fix corrupted bash.bashrc if needed (check for syntax errors)
    if [ -f /etc/bash.bashrc ]; then
      if ! bash -n /etc/bash.bashrc 2>/dev/null; then
        echo "⚠️  /etc/bash.bashrc has syntax errors, attempting to fix..."
        # Try to restore from backup if it exists and is valid
        if [ -f /etc/bash.bashrc.backup-before-nix ] && bash -n /etc/bash.bashrc.backup-before-nix 2>/dev/null; then
          cp /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc
          echo "Restored from backup"
        else
          echo "⚠️  Could not auto-fix. Manual intervention may be needed."
        fi
      fi
    fi

    echo "Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --daemon --yes || {
      echo "❌ Nix installation failed"
      exit 1
    }

    echo "✅ Nix installed!"
  else
    echo "✅ Nix already installed"
  fi

  # Source nix-daemon.sh for current session (always do this)
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  # Verify Nix is working
  if ! command -v nix &> /dev/null; then
    echo "❌ Error: Nix installed but not in PATH"
    echo "Trying to source from system profile..."
    if [ -f /etc/profile.d/nix.sh ]; then
      . /etc/profile.d/nix.sh
    fi
    if ! command -v nix &> /dev/null; then
      echo "❌ Nix still not found. Please check installation."
      exit 1
    fi
  fi

  # Enable flakes
  mkdir -p ~/.config/nix
  if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  fi

  nix --version
EOF

echo ""
echo "📦 Building VM image on Proxmox host..."
echo ""

# Copy the nix directory to Proxmox host
ssh "$PROXMOX_HOST" "mkdir -p ~/homelab-build"
rsync -avz --exclude='.git' --exclude='result*' ./nix/ "$PROXMOX_HOST:~/homelab-build/nix/"

# Build the image
ssh "$PROXMOX_HOST" << 'EOF'
  set -euo pipefail

  cd ~/homelab-build/nix

  # Source nix - try multiple locations
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -f /etc/profile.d/nix.sh ]; then
    . /etc/profile.d/nix.sh
  fi

  # Verify Nix is available
  if ! command -v nix &> /dev/null; then
    echo "❌ Error: Nix command not found. Installation may have failed."
    echo "Checking Nix installation..."
    ls -la /nix/var/nix/profiles/default/etc/profile.d/ || true
    exit 1
  fi

  echo "Nix version: $(nix --version)"
  echo "Building VM image..."
  nix run github:nix-community/nixos-generators -- \
    --format raw \
    --flake '.#template' \
    -o result

  # Convert to qcow2
  # nixos-generators may output nixos.raw or nixos.img depending on format
  RAW_IMAGE=""
  if [ -f result/nixos.raw ]; then
    RAW_IMAGE="result/nixos.raw"
  elif [ -f result/nixos.img ]; then
    RAW_IMAGE="result/nixos.img"
  else
    echo "❌ Error: Could not find result/nixos.raw or result/nixos.img"
    echo "Contents of result/:"
    ls -la result/
    exit 1
  fi

  echo "Converting $RAW_IMAGE to qcow2..."
  qemu-img convert -f raw -O qcow2 "$RAW_IMAGE" nixos-template.qcow2
  ls -lh nixos-template.qcow2
  echo "✅ Image built: ~/homelab-build/nix/nixos-template.qcow2"
EOF

echo ""
echo "✅ Build complete!"
echo ""
echo "Next steps:"
echo "1. Download the image: scp $PROXMOX_HOST:~/homelab-build/nix/nixos-template.qcow2 ./"
echo "2. Upload to Proxmox storage"
echo "3. Create VM from image and convert to template"
