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

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/)
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
└── k3s/                        # K3s related configs
```

## Services

| Service        | Description            |
| -------------- | ---------------------- |
| Home Assistant | Home automation        |
| Traefik        | Reverse proxy          |
| Bitwarden      | Password manager       |
| K3s            | Lightweight Kubernetes |

## License

MIT
