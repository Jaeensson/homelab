variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://192.168.2.10:8006/"
}

variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
  default     = "homelab"
}

variable "cluster_domain" {
  description = "Cluster domain for Kubernetes API"
  type        = string
  default     = "cluster.local"
}

variable "talos_version" {
  description = "Talos OS version to use"
  type        = string
  default     = "1.12.4"
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS servers for the nodes"
  type        = list(string)
  default     = ["192.168.1.21"]
}

variable "proxmox_node" {
  description = "Proxmox node name VMs will where be created"
  type        = string
  default     = "pve"
}

variable "proxmox_storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "proxmox_snippets_storage" {
  description = "Proxmox storage pool for cloud-init snippets"
  type        = string
  default     = "local"
}

variable "controlplane_vm_id" {
  description = "VM ID for controlplane node"
  type        = number
  default     = 101
}

variable "worker_vm_ids" {
  description = "VM IDs for worker nodes"
  type        = list(number)
  default     = [102, 103]
}

variable "controlplane_ip" {
  description = "IP address for controlplane node"
  type        = string
  default     = "192.168.2.10"
}

variable "worker_ips" {
  description = "IP addresses for worker nodes"
  type        = list(string)
  default     = ["192.168.2.11", "192.168.2.12"]
}

variable "vm_cpu" {
  description = "Number of vCPUs for each VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory in MB for each VM"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Disk size in GB for each VM"
  type        = number
  default     = 50
}

variable "vm_network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}
