# Proxmox Terraform Configuration

Infrastructure as Code for provisioning VMs on Proxmox VE using the [Telmate Terraform Provider](https://github.com/Telmate/terraform-provider-proxmox).

## Prerequisites

1. **Terraform** - [Install Terraform](https://developer.hashicorp.com/terraform/install)
2. **Proxmox API Token** - Create one in Proxmox UI: Datacenter → Permissions → API Tokens
3. **VM Template** - A cloud-init enabled template (see below)

## Quick Start

### 1. Create API Token in Proxmox

```bash
# Or via CLI on your Proxmox host:
pveum user token add root@pam terraform --privsep 0
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## Usage

```bash
# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy all VMs
terraform destroy

# Destroy specific resource
terraform destroy -target=proxmox_vm_qemu.example
```

## Creating a Cloud-Init Template

On your Proxmox host:

```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM
qm create 9000 --name ubuntu-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Configure VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

## Configuration Examples

### Basic VM

```hcl
resource "proxmox_vm_qemu" "web" {
  name        = "web-server"
  target_node = "pve"
  clone       = "ubuntu-template"

  cores  = 2
  memory = 2048

  os_type   = "cloud-init"
  ciuser    = "ubuntu"
  sshkeys   = file("~/.ssh/id_rsa.pub")
  ipconfig0 = "ip=dhcp"

  disks {
    scsi {
      scsi0 {
        disk {
          size    = 32
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }
}
```

### Multiple VMs with for_each

```hcl
variable "vms" {
  default = {
    "web-1"    = { cores = 2, memory = 2048, ip = "192.168.1.10/24" }
    "web-2"    = { cores = 2, memory = 2048, ip = "192.168.1.11/24" }
    "db-1"     = { cores = 4, memory = 8192, ip = "192.168.1.20/24" }
  }
}

resource "proxmox_vm_qemu" "servers" {
  for_each = var.vms

  name        = each.key
  target_node = "pve"
  clone       = "ubuntu-template"

  cores  = each.value.cores
  memory = each.value.memory

  os_type   = "cloud-init"
  ciuser    = "ubuntu"
  ipconfig0 = "ip=${each.value.ip},gw=192.168.1.1"

  disks {
    scsi {
      scsi0 {
        disk {
          size    = 32
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }
}
```

## Environment Variables

Instead of `terraform.tfvars`, you can use environment variables:

```bash
export TF_VAR_proxmox_url="https://192.168.1.100:8006/api2/json"
export TF_VAR_proxmox_token_id="root@pam!terraform"
export TF_VAR_proxmox_token_secret="your-secret"
```

## Resources

- [Telmate Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [proxmox_vm_qemu Resource](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/vm_qemu)
- [Proxmox API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
