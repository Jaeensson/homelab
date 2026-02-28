variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "proxmox_storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "cpu_type" {
  description = "CPU architecture type"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "talos_version" {
  description = "Talos OS version to use"
  type        = string
  default     = "1.12.4"
}

variable "talos_extensions" {
  type        = list(string)
  default     = []
  description = "List of Talos system extensions to install"
}

variable "cluster_endpoint" {
  description = "Talos cluster endpoint"
  type        = string
  default     = "192.168.0.123"
}

variable "cluster_name" {
  description = "The name of the k8s cluster"
  type        = string
  default     = "talos-cluster"
}

variable "network_gateway" {
  description = "Gateway for network configuration"
  type        = string
  default     = "192.168.1.1"
}

variable "network_netmask" {
  description = "Netmask for network configuration"
  type        = string
  default     = "/24"
}

variable "network_dns" {
  description = "Netmask for network configuration"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "network_bridge" {
  description = "Proxmox network bridge device"
  type        = string
  default     = "vmbr0"
}

variable "vm_control_planes" {
  description = "The vms running as k8s control planes"
  type = list(object({
    vm_id        = number
    proxmox_node = string
    node_name    = string
    ip           = string
    cpu_cores    = number
    ram_mb       = number
    disk_size_gb = number
  }))
  default = []
}

variable "vm_workers" {
  description = "The vms running as k8s workers"
  type = list(object({
    vm_id        = number
    proxmox_node = string
    node_name    = string
    ip           = string
    cpu_cores    = number
    ram_mb       = number
    disk_size_gb = number
  }))
  default = []
}