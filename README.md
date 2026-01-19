# Homelab

Infrastructure as Code for my homelab running on Proxmox VE.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Proxmox VE                              │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │
│  │  k3s-master   │  │ k3s-worker-1  │  │ k3s-worker-2  │        │
│  │   (2GB RAM)   │  │   (2GB RAM)   │  │   (2GB RAM)   │        │
│  └───────────────┘  └───────────────┘  └───────────────┘        │
│         │                   │                   │               │
│         └───────────────────┴───────────────────┘               │
│                         K3s Cluster                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Docker: Home Assistant, Traefik, Bitwarden, etc.       │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Workflow

```
┌───────────────────┐         ┌───────────┐         ┌───────────┐
│      Ansible      │────────►│ Terraform │────────►│  Ansible  │
│                   │         │           │         │           │
│  Create Template  │         │ Deploy VM │         │ Configure │
└───────────────────┘         └───────────┘         └───────────┘
        │                           │                     │
        ▼                           ▼                     ▼
 ubuntu-template              k3s-master             k3s cluster
   (base image)               k3s-worker-1           ready to use
                              k3s-worker-2
```

| Tool          | Purpose                               | Runs                               |
| ------------- | ------------------------------------- | ---------------------------------- |
| **Ansible**   | Create Ubuntu template from cloud img | Once (or when updating base image) |
| **Terraform** | Deploy VMs by cloning template        | When adding/changing VMs           |
| **Ansible**   | Install k3s and configure cluster     | After VM deployment                |

## What is a Template?

A **template** is a Proxmox feature - a read-only VM that can only be cloned, not started directly.

```
ubuntu-template (VMID 9000)          Terraform clones to:
┌─────────────────────────┐          ┌─────────────────────────┐
│  Ubuntu 24.04 LTS       │    ───►  │  k3s-master (VMID 100)  │
│  cloud-init ready       │    ───►  │  k3s-worker-1 (VMID 101)│
│  25GB disk              │    ───►  │  k3s-worker-2 (VMID 102)│
└─────────────────────────┘          └─────────────────────────┘
      (frozen image)                    (running VMs)
```

|               | Template | VM                |
| ------------- | -------- | ----------------- |
| Can start?    | ❌       | ✅                |
| Can modify?   | ❌       | ✅                |
| Can clone?    | ✅       | ✅                |
| Uses RAM/CPU? | ❌       | ✅ (when running) |

Similar concepts exist on other platforms: AWS AMIs, Azure VM Images, Docker Images.

## Secrets Management

This repo uses **SOPS + age** for GitOps-friendly secret management. Encrypted secrets are committed to Git and decrypted at deploy time.

```
secrets/
├── age-key.txt      # Your private key (NEVER commit - gitignored)
└── README.md        # Setup instructions

# Encrypted files (safe to commit)
k3s/my-secret.enc.yaml
bitwarden/secrets.enc.env
```

### Quick Setup

```bash
# Install tools (macOS)
brew install sops age direnv pre-commit

# Generate your key
age-keygen -o secrets/age-key.txt

# Add public key to .sops.yaml, then enable direnv
direnv allow

# Install pre-commit hooks (prevents committing unencrypted secrets)
pre-commit install

# Now SOPS_AGE_KEY_FILE is auto-set when you're in this repo!
sops --encrypt secret.yaml > secret.enc.yaml
```

See [`secrets/README.md`](secrets/README.md) for detailed instructions.

**Pre-commit hooks** prevent accidentally committing unencrypted secrets:

```bash
$ git add secrets.yaml  # Unencrypted!
$ git commit -m "oops"
Check for unencrypted secrets..........................................Failed
- hook id: no-unencrypted-secrets
- ERROR: Unencrypted secret file detected: secrets.yaml
```

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/)
- [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age) for secrets
- [direnv](https://direnv.net/) for auto-env vars
- [pre-commit](https://pre-commit.com/) for git hooks
- Proxmox VE with API token
- SSH access to Proxmox host

### 1. Create Template

```bash
cd ansible
ansible-playbook playbooks/create-template.yml -i inventory/proxmox.yml
```

### 2. Deploy VMs

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox details
terraform init
terraform apply
```

### 3. Configure K3s Cluster

```bash
# Generate Ansible inventory from Terraform
cd terraform
terraform output -raw ansible_inventory > ../ansible/inventory/hosts.yml

# Install k3s
cd ../ansible
ansible all -m ping  # Test connectivity
ansible-playbook playbooks/k3s.yml

# Use your cluster
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl get nodes
```

## Directory Structure

```
homelab/
├── .sops.yaml                  # SOPS encryption rules
├── .pre-commit-config.yaml     # Git hooks config
├── .envrc                      # direnv auto-env vars
├── secrets/                    # Age key storage (gitignored)
│   ├── age-key.txt             # Private key (DO NOT COMMIT)
│   └── README.md               # SOPS setup guide
├── scripts/                    # Helper scripts
│   ├── check-secrets.sh        # Pre-commit: block unencrypted
│   └── verify-sops.sh          # Pre-commit: verify encryption
├── ansible/                    # Configuration management
│   ├── inventory/
│   │   ├── proxmox.yml         # Proxmox host
│   │   └── hosts.yml           # K3s nodes (generated)
│   ├── playbooks/
│   │   ├── create-template.yml # Create VM template
│   │   └── k3s.yml             # Install k3s
│   └── roles/k3s/              # K3s role
├── terraform/                  # Infrastructure deployment
│   ├── vms.tf                  # VM definitions
│   └── outputs.tf              # Generates Ansible inventory
├── homeassistant/              # Home Assistant config
├── bitwarden/                  # Bitwarden config
├── minio/                      # S3-compatible storage
├── prometheus/                 # Prometheus + node-exporter monitoring
└── k3s/                        # K3s related configs
```

## Services

| Service        | Description                             |
| -------------- | --------------------------------------- |
| Home Assistant | Home automation                         |
| Traefik        | Reverse proxy                           |
| Bitwarden      | Password manager                        |
| MinIO          | S3-compatible storage (TF state)        |
| Prometheus     | Metrics collection (with node-exporter) |
| K3s            | Lightweight Kubernetes                  |

## License

MIT
