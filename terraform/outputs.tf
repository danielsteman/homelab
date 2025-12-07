output "k3s_master_ip" {
  description = "IP address of the k3s master"
  value       = proxmox_vm_qemu.k3s_master.default_ipv4_address
}

output "k3s_worker_ips" {
  description = "IP addresses of k3s workers"
  value       = proxmox_vm_qemu.k3s_workers[*].default_ipv4_address
}

# Generate Ansible inventory
output "ansible_inventory" {
  description = "Ansible inventory content - save to ansible/inventory/hosts.yml"
  value       = <<-EOT
all:
  children:
    k3s_cluster:
      children:
        master:
          hosts:
            k3s-master:
              ansible_host: ${coalesce(proxmox_vm_qemu.k3s_master.default_ipv4_address, "PENDING")}
        workers:
          hosts:
%{for i, ip in proxmox_vm_qemu.k3s_workers[*].default_ipv4_address~}
            k3s-worker-${i + 1}:
              ansible_host: ${coalesce(ip, "PENDING")}
%{endfor~}

  vars:
    ansible_user: ubuntu
    ansible_python_interpreter: /usr/bin/python3
EOT
}
