packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variables
variable "proxmox_url" {
  type    = string
  default = env("PROXMOX_URL")
}

variable "proxmox_token_id" {
  type    = string
  default = env("PROXMOX_TOKENID")
}

variable "proxmox_token_secret" {
  type      = string
  sensitive = true
  default   = env("PROXMOX_SECRET")
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "vm_id" {
  type    = number
  default = 9000
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "iso_storage_pool" {
  type    = string
  default = "local"
}

# Ubuntu cloud image source
source "proxmox-iso" "ubuntu-template" {
  # Proxmox connection
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token_secret
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node

  # VM settings
  vm_id   = var.vm_id
  vm_name = "ubuntu-template"

  # ISO - Ubuntu Server 22.04 (download to Proxmox first)
  iso_file = "${var.iso_storage_pool}:iso/ubuntu-22.04.3-live-server-amd64.iso"

  # Hardware
  cores      = 2
  memory     = 2048
  cpu_type   = "host"
  qemu_agent = true

  # Disk
  scsi_controller = "virtio-scsi-pci"
  disks {
    disk_size    = "25G"
    storage_pool = var.storage_pool
    type         = "scsi"
  }

  # Network
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-init
  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool

  # Boot and autoinstall
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot      = "c"
  boot_wait = "5s"

  # HTTP server for autoinstall
  http_directory = "http"

  # SSH connection (after install)
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"

  # Template settings
  template_name        = "ubuntu-template"
  template_description = "Ubuntu 22.04 LTS cloud-init template - built with Packer"
  unmount_iso          = true
}

build {
  sources = ["source.proxmox-iso.ubuntu-template"]

  # Install cloud-init and clean up
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent cloud-init",
      "sudo systemctl enable qemu-guest-agent",
      "sudo cloud-init clean",
      "sudo rm -f /etc/machine-id /var/lib/dbus/machine-id",
      "sudo truncate -s 0 /etc/hostname",
      "sudo sync"
    ]
  }
}
