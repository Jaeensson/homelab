module "talos_cluster" {
  source           = "./modules/talos_cluster"
  proxmox_endpoint = var.proxmox_endpoint
  proxmox_token    = var.proxmox_token

  talos_version = "1.12.5"
  talos_extensions = [
    "siderolabs/i915",
    "siderolabs/intel-ucode",
    "siderolabs/iscsi-tools",
    "siderolabs/util-linux-tools"
  ]

  cluster_name     = "homelab-prod"
  cluster_endpoint = "192.168.2.100"

  network_gateway = "192.168.1.1"
  network_netmask = "/22"
  network_dns     = ["192.168.1.21", "192.168.1.1"]
  network_bridge  = "vmbr0"

  cpu_type = "x86-64-v2-AES"

  vm_control_planes = [
    {
      vm_id        = 6000
      proxmox_node = var.proxmox_node
      node_name    = "control-1"
      ip           = "192.168.2.100"
      cpu_cores    = 4
      ram_mb       = 16384
      system_disk_size_gb = 50
      storage_disk_size_gb = 100
    }
  ]

  vm_workers = [
    {
      vm_id        = 7000
      proxmox_node = var.proxmox_node
      node_name    = "worker-1"
      ip           = "192.168.2.101"
      cpu_cores    = 4
      ram_mb       = 16384
      system_disk_size_gb = 50
      storage_disk_size_gb = 100
    }
  ]
}

output "talosconfig" {
  value       = module.talos_cluster.talosconfig
  sensitive   = true
  description = "Talos configuration"
}

output "kubeconfig" {
  value       = module.talos_cluster.kubeconfig
  sensitive   = true
  description = "K8s configuration"
}