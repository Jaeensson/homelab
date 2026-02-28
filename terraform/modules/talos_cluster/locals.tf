locals {
  all_nodes = concat(
    [for node in var.vm_control_planes : {
      node_type    = "controlplane"
      vm_id        = node.vm_id
      proxmox_node = node.proxmox_node
      node_name    = node.node_name
      ip           = node.ip
      cpu_cores    = node.cpu_cores
      ram_mb       = node.ram_mb
      disk_size_gb = node.disk_size_gb
    }],
    [for node in var.vm_workers : {
      node_type    = "worker"
      vm_id        = node.vm_id
      proxmox_node = node.proxmox_node
      node_name    = node.node_name
      ip           = node.ip
      cpu_cores    = node.cpu_cores
      ram_mb       = node.ram_mb
      disk_size_gb = node.disk_size_gb
    }]
  )

  all_proxmox_nodes = toset(distinct([for node in local.all_nodes : node.proxmox_node]))
}
