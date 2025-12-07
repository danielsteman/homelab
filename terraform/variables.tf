# Proxmox connection
variable "proxmox_url" {
  description = "Proxmox API URL (e.g., https://192.168.1.100:8006/api2/json)"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID (e.g., root@pam!mytoken)"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

# VM defaults
variable "template_name" {
  description = "Name of the VM template to clone"
  type        = string
  default     = "ubuntu-template"
}

variable "storage" {
  description = "Storage pool for VMs"
  type        = string
  default     = "local-lvm"
}

variable "ssh_keys" {
  description = "SSH public keys for cloud-init"
  type        = string
  default     = ""
}

variable "default_user" {
  description = "Default cloud-init user"
  type        = string
  default     = "ubuntu"
}
