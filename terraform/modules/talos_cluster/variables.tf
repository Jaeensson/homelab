variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
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
}

variable "dns_servers" {
  description = "DNS servers for the nodes"
  type        = list(string)
}

variable "proxmox_node" {
  description = "Proxmox node name where VMs will be created"
  type        = string
}

variable "proxmox_storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
}

variable "proxmox_snippets_storage" {
  description = "Proxmox storage pool for cloud-init snippets"
  type        = string
  default     = "local"
}

variable "controlplane_vm_id" {
  description = "VM ID for controlplane node"
  type        = number
}

variable "worker_vm_ids" {
  description = "VM IDs for worker nodes"
  type        = list(number)
}

variable "controlplane_ip" {
  description = "IP address for controlplane node"
  type        = string
}

variable "worker_ips" {
  description = "IP addresses for worker nodes"
  type        = list(string)
}

variable "vm_cpu" {
  description = "Number of vCPUs for each VM"
  type        = number
}

variable "vm_memory" {
  description = "Memory in MB for each VM"
  type        = number
}

variable "vm_disk_size" {
  description = "Disk size in GB for each VM"
  type        = number
}

variable "vm_network_bridge" {
  description = "Proxmox network bridge"
  type        = string
}

variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}
