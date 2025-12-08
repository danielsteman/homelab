# K3s Master Node
resource "proxmox_vm_qemu" "k3s_master" {
  name        = "k3s-master"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  cores   = 2
  memory  = 2048 # 2 GB
  sockets = 1
  scsihw  = "virtio-scsi-pci"

  os_type    = "cloud-init"
  ciuser     = var.default_user
  sshkeys    = var.ssh_keys
  ipconfig0  = "ip=dhcp"
  nameserver = "1.1.1.1"

  disk {
    type    = "scsi"
    storage = var.storage
    size    = "25G"
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  tags = "kubernetes,master"

  lifecycle {
    ignore_changes = [network]
  }
}

# K3s Worker Nodes
resource "proxmox_vm_qemu" "k3s_workers" {
  count = 2

  name        = "k3s-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  cores   = 2
  memory  = 2048 # 2 GB
  sockets = 1
  scsihw  = "virtio-scsi-pci"

  os_type   = "cloud-init"
  ciuser    = var.default_user
  sshkeys   = var.ssh_keys
  ipconfig0 = "ip=dhcp"

  disk {
    type    = "scsi"
    storage = var.storage
    size    = "25G"
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  tags = "kubernetes,worker"

  lifecycle {
    ignore_changes = [network]
  }
}
