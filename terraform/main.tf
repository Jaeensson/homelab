module "talos_cluster" {
  source = "./modules/talos_cluster"

  cluster_name    = var.cluster_name
  cluster_domain  = var.cluster_domain
  talos_version   = var.talos_version
  gateway         = var.gateway
  dns_servers     = var.dns_servers
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage

  proxmox_snippets_storage = var.proxmox_snippets_storage

  controlplane_vm_id = var.controlplane_vm_id
  worker_vm_ids      = var.worker_vm_ids

  controlplane_ip = var.controlplane_ip
  worker_ips      = var.worker_ips

  vm_cpu            = var.vm_cpu
  vm_memory         = var.vm_memory
  vm_disk_size      = var.vm_disk_size
  vm_network_bridge = var.vm_network_bridge

  proxmox_token = var.proxmox_token
}
