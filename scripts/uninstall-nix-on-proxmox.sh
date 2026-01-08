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

  # Check if Nix is actually installed (check for /nix directory, not just command)
  NIX_INSTALLED=false
  if [ -d /nix ] || command -v nix &> /dev/null; then
    NIX_INSTALLED=true
  fi

  if [ "$NIX_INSTALLED" = false ]; then
    echo "ℹ️  No Nix installation detected, but cleaning up any artifacts..."
  else
    echo "Stopping Nix daemon..."
    sudo systemctl stop nix-daemon.service 2>/dev/null || true
    sudo systemctl disable nix-daemon.service 2>/dev/null || true
  fi

  echo "🗑️  Removing backup files (from failed installs)..."
  sudo rm -f /etc/bash.bashrc.backup-before-nix
  sudo rm -f /etc/bashrc.backup-before-nix
  sudo rm -f /etc/zshrc.backup-before-nix
  sudo rm -f /etc/zsh/zshrc.backup-before-nix

  echo "Removing Nix daemon systemd service..."
  sudo rm -f /etc/systemd/system/nix-daemon.service
  sudo rm -f /etc/systemd/system/nix-daemon.socket
  sudo rm -f /etc/systemd/system/multi-user.target.wants/nix-daemon.service
  sudo rm -f /etc/systemd/system/sockets.target.wants/nix-daemon.socket

  echo "Removing Nix configuration..."
  sudo rm -rf /etc/nix
  rm -rf ~/.config/nix
  rm -rf ~/.nix-profile
  rm -rf ~/.nix-defexpr

  echo "Removing Nix from shell profiles..."
  # Remove from /etc/profile.d/nix.sh if it exists
  sudo rm -f /etc/profile.d/nix.sh

  # Clean up /etc/bash.bashrc (remove Nix lines, fix syntax errors)
  if [ -f /etc/bash.bashrc ]; then
    # Remove Nix-related lines
    sudo sed -i '/nix-daemon.sh/d' /etc/bash.bashrc || true
    sudo sed -i '/NIX_REMOTE/d' /etc/bash.bashrc || true
    # Remove orphaned 'fi' statements (common after failed installs)
    sudo sed -i '/^fi$/d' /etc/bash.bashrc || true

    # Verify syntax
    if bash -n /etc/bash.bashrc 2>/dev/null; then
      echo "  ✅ /etc/bash.bashrc syntax is valid"
    else
      echo "  ⚠️  /etc/bash.bashrc still has syntax errors - manual fix may be needed"
    fi
  fi

  # Clean up other system shell configs
  for file in /etc/bashrc /etc/zshrc /etc/zsh/zshrc; do
    if [ -f "$file" ]; then
      sudo sed -i '/nix-daemon.sh/d' "$file" || true
      sudo sed -i '/NIX_REMOTE/d' "$file" || true
    fi
  done

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
    if id "nixbld$i" &>/dev/null 2>&1; then
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
  echo "✅ Nix has been completely removed!"
  echo ""
  echo "Note: You may need to log out and back in for all changes to take effect."
EOF

echo ""
echo "✅ Uninstall complete!"
