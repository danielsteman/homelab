# Ansible - K3s Cluster Setup

Ansible playbooks for installing and configuring a k3s cluster on Proxmox VMs.

## Prerequisites

1. **Ansible** installed locally
   ```bash
   # macOS
   brew install ansible

   # Ubuntu/Debian
   sudo apt install ansible
   ```

2. **VMs deployed** via Terraform
3. **SSH access** to all nodes (via cloud-init SSH key)

## Workflow

### 1. Deploy VMs with Terraform

```bash
cd ../terraform
terraform apply
```

### 2. Update Ansible inventory with VM IPs

```bash
# Option A: Copy from Terraform output
cd ../terraform
terraform output -raw ansible_inventory > ../ansible/inventory/hosts.yml

# Option B: Manually edit inventory/hosts.yml with IPs from:
terraform output
```

### 3. Test connectivity

```bash
cd ../ansible
ansible all -m ping
```

### 4. Install k3s cluster

```bash
ansible-playbook playbooks/k3s.yml
```

### 5. Use your cluster

After the playbook completes, `kubeconfig.yaml` is saved locally:

```bash
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl get nodes
```

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   └── hosts.yml            # Inventory (update with VM IPs)
├── playbooks/
│   └── k3s.yml              # Main k3s installation playbook
├── roles/
│   └── k3s/
│       ├── tasks/
│       │   ├── main.yml     # Task router
│       │   ├── server.yml   # Master node tasks
│       │   └── agent.yml    # Worker node tasks
│       └── defaults/
│           └── main.yml     # Default variables
├── kubeconfig.yaml          # Generated after install (gitignored)
└── README.md
```

## What the playbook does

1. **Master node**:
   - Installs k3s server
   - Disables Traefik (you can use your own ingress)
   - Fetches kubeconfig to local machine
   - Stores join token for workers

2. **Worker nodes**:
   - Installs k3s agent
   - Joins the cluster using master's token
   - Verifies node joined successfully

## Customization

### Change k3s version

Edit `roles/k3s/defaults/main.yml`:

```yaml
k3s_version: "v1.28.4+k3s1"
```

### Enable Traefik

Remove `--disable traefik` from `roles/k3s/tasks/server.yml`.

### Add more workers

1. Update Terraform: `count = 3` in `vms.tf`
2. Run `terraform apply`
3. Update inventory with new IPs
4. Run `ansible-playbook playbooks/k3s.yml`

## Troubleshooting

**SSH connection refused**: VMs might still be booting. Wait a minute and retry.

**Python not found**: Ensure cloud-init installed Python, or install manually:
```bash
ansible all -m raw -a "apt-get update && apt-get install -y python3"
```

**Node not joining**: Check firewall allows port 6443 between nodes.
