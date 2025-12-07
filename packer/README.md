# Packer - Ubuntu Template for Proxmox

Creates a cloud-init enabled Ubuntu 22.04 template using [HashiCorp Packer](https://www.packer.io/).

## Prerequisites

1. **Packer** - [Install Packer](https://developer.hashicorp.com/packer/install)
2. **Ubuntu ISO** on Proxmox storage

### Download Ubuntu ISO to Proxmox

On your Proxmox host:

```bash
cd /var/lib/vz/template/iso
wget https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso
```

## Usage

### 1. Set environment variables

```bash
export PROXMOX_URL="https://192.168.1.100:8006/api2/json"
export PROXMOX_TOKENID="root@pam!packer"
export PROXMOX_SECRET="your-api-token-secret"
```

### 2. Initialize Packer

```bash
cd packer
packer init ubuntu-template.pkr.hcl
```

### 3. Build template

```bash
# Validate first
packer validate ubuntu-template.pkr.hcl

# Build
packer build ubuntu-template.pkr.hcl

# Or with variables file
packer build -var-file=variables.pkrvars.hcl ubuntu-template.pkr.hcl
```

### 4. Use with Terraform

Once the template is created, deploy VMs:

```bash
cd ../terraform
terraform apply
```

## What it does

1. Creates a VM from Ubuntu Server ISO
2. Runs autoinstall with cloud-init configuration
3. Installs qemu-guest-agent
4. Cleans up for templating (removes machine-id, etc.)
5. Converts VM to template

## Customization

Edit `http/user-data` to customize:

- Default username/password
- Packages to install
- Locale/keyboard settings

## Troubleshooting

**Build hangs at boot**: Ensure the ISO is downloaded correctly and the path matches.

**SSH connection fails**: The autoinstall might still be running. Increase `ssh_timeout`.

**Network issues**: Packer needs to reach the VM's IP. Ensure your network/firewall allows this.
