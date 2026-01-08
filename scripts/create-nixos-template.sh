#!/usr/bin/env bash
# Create NixOS template in Proxmox from qcow2 image
# Usage: ./scripts/create-nixos-template.sh [proxmox-host] [image-path] [storage] [vmid]

set -euo pipefail

PROXMOX_HOST="${1:-root@192.168.68.251}"
IMAGE_PATH="${2:-~/homelab-build/nix/nixos-template.qcow2}"
STORAGE="${3:-local-lvm}"
TEMPLATE_VMID="${4:-9001}"
TEMPLATE_NAME="nixos-template"

echo "🚀 Creating NixOS template in Proxmox"
echo "  Host: $PROXMOX_HOST"
echo "  Image: $IMAGE_PATH"
echo "  Storage: $STORAGE"
echo "  VMID: $TEMPLATE_VMID"
echo ""

ssh "$PROXMOX_HOST" << EOF
  set -euo pipefail

  # Expand tilde in path
  IMAGE_PATH="${IMAGE_PATH/#\~/$HOME}"

  if [ ! -f "\$IMAGE_PATH" ]; then
    echo "❌ Error: Image not found at \$IMAGE_PATH"
    exit 1
  fi

  echo "📦 Image found: \$(ls -lh \$IMAGE_PATH)"

  # Check if template already exists
  if qm status $TEMPLATE_VMID &>/dev/null; then
    echo "⚠️  Template VM $TEMPLATE_VMID already exists"
    read -p "Delete and recreate? (yes/no): " -r
    if [[ \$REPLY =~ ^[Yy][Ee][Ss]\$ ]]; then
      echo "Stopping VM if running..."
      qm stop $TEMPLATE_VMID 2>/dev/null || true
      echo "Destroying existing VM..."
      qm destroy $TEMPLATE_VMID --purge || true
    else
      echo "Aborted."
      exit 1
    fi
  fi

  echo "Creating VM..."
  qm create $TEMPLATE_VMID \\
    --name $TEMPLATE_NAME \\
    --memory 2048 \\
    --cores 2 \\
    --scsihw virtio-scsi-pci \\
    --net0 virtio,bridge=vmbr0

  echo "Importing disk image (this may take a few minutes)..."
  qm importdisk $TEMPLATE_VMID "\$IMAGE_PATH" $STORAGE

  echo "Attaching imported disk..."
  qm set $TEMPLATE_VMID --scsi0 $STORAGE:vm-$TEMPLATE_VMID-disk-0

  echo "Configuring boot order..."
  qm set $TEMPLATE_VMID --boot order=scsi0

  echo "Configuring serial console and guest agent..."
  qm set $TEMPLATE_VMID --serial0 socket --vga serial0
  qm set $TEMPLATE_VMID --agent enabled=1

  echo "Converting to template..."
  qm template $TEMPLATE_VMID

  echo ""
  echo "✅ Template '$TEMPLATE_NAME' (VMID: $TEMPLATE_VMID) created successfully!"
  echo ""
  echo "You can now clone this template to create new VMs:"
  echo "  qm clone $TEMPLATE_VMID <new-vmid> --name <new-vm-name>"
EOF

echo ""
echo "✅ Template creation complete!"
