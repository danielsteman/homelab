#!/usr/bin/env bash
# Uninstall Nix from Proxmox host
# Usage: ./scripts/uninstall-nix-on-proxmox.sh [proxmox-host]

set -euo pipefail

PROXMOX_HOST="${1:-root@192.168.68.251}"

echo "🗑️  Uninstalling Nix from Proxmox host: $PROXMOX_HOST"
echo ""
echo "⚠️  WARNING: This will remove Nix and all installed packages!"
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "Aborted."
  exit 1
fi

ssh "$PROXMOX_HOST" << 'EOF'
  set -euo pipefail

  if ! command -v nix &> /dev/null; then
    echo "✅ Nix is not installed, nothing to remove."
    exit 0
  fi

  echo "Stopping Nix daemon..."
  if systemctl list-units --full -all | grep -Fq "nix-daemon.service"; then
    sudo systemctl stop nix-daemon.service || true
    sudo systemctl disable nix-daemon.service || true
  fi

  echo "Removing Nix daemon systemd service..."
  if [ -f /etc/systemd/system/nix-daemon.service ]; then
    sudo rm -f /etc/systemd/system/nix-daemon.service
  fi
  if [ -f /etc/systemd/system/multi-user.target.wants/nix-daemon.service ]; then
    sudo rm -f /etc/systemd/system/multi-user.target.wants/nix-daemon.service
  fi

  echo "Removing Nix configuration..."
  sudo rm -rf /etc/nix
  rm -rf ~/.config/nix
  rm -rf ~/.nix-profile
  rm -rf ~/.nix-defexpr

  echo "Removing Nix from shell profiles..."
  # Remove from /etc/profile.d/nix.sh if it exists
  if [ -f /etc/profile.d/nix.sh ]; then
    sudo rm -f /etc/profile.d/nix.sh
  fi

  # Remove from /etc/bash.bashrc
  if [ -f /etc/bash.bashrc ]; then
    sudo sed -i '/nix-daemon.sh/d' /etc/bash.bashrc || true
  fi

  # Remove from user's .bashrc, .bash_profile, .zshrc, etc.
  for file in ~/.bashrc ~/.bash_profile ~/.profile ~/.zshrc; do
    if [ -f "$file" ]; then
      sed -i '/nix-daemon.sh/d' "$file" || true
      sed -i '/NIX_REMOTE/d' "$file" || true
    fi
  done

  echo "Removing Nix users and groups..."
  # Remove nixbld users (usually nixbld1 through nixbld32)
  for i in {1..32}; do
    if id "nixbld$i" &>/dev/null; then
      sudo userdel "nixbld$i" 2>/dev/null || true
    fi
  done

  # Remove nixbld group
  if getent group nixbld &>/dev/null; then
    sudo groupdel nixbld 2>/dev/null || true
  fi

  # Remove nix-remote group if it exists
  if getent group nix-remote &>/dev/null; then
    sudo groupdel nix-remote 2>/dev/null || true
  fi

  echo "Removing Nix store and state..."
  sudo rm -rf /nix

  echo "Reloading systemd..."
  sudo systemctl daemon-reload || true

  echo ""
  echo "✅ Nix has been uninstalled!"
  echo ""
  echo "Note: You may need to log out and back in for all changes to take effect."
EOF

echo ""
echo "✅ Uninstall complete!"
