# K3s Master Node
# Note: Network and user configuration will be handled by NixOS configs, not cloud-init
resource "proxmox_vm_qemu" "k3s_master" {
  name        = "k3s-master"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  memory = 2048 # 2 GB
  scsihw = "virtio-scsi-pci"

  cpu {
    cores = 2
  }

  disk {
    storage = var.storage
    size    = "25G"
    slot    = "virtio0"
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  tags = "kubernetes,master"

  lifecycle {
    ignore_changes = [network]
  }
}

# K3s Worker Nodes
# Note: Network and user configuration will be handled by NixOS configs, not cloud-init
resource "proxmox_vm_qemu" "k3s_workers" {
  count = 2

  name        = "k3s-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  memory = 2048 # 2 GB
  scsihw = "virtio-scsi-pci"

  cpu {
    cores = 2
  }

  disk {
    storage = var.storage
    size    = "25G"
    slot    = "virtio0"
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  tags = "kubernetes,worker"

  lifecycle {
    ignore_changes = [network]
  }
}
