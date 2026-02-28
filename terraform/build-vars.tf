locals {
  nodes   = yamldecode(file("vars/nodes.yaml"))
  network = yamldecode(file("vars/network.yaml"))

  controlplanes = {
    for index, node in local.nodes.controlplanes :
    "controlplanes${index}" => {
      name      = format("talos-ctrl-%d", index)
      node_type = "controlplane"
      id        = 1000 + index
      cores     = node.cores
      ram       = node.ram
      ip        = node.ip
      disk_size = node.disk_size
    }
  }

  workers = {
    for index, node in local.nodes.workers :
    "worker${index}" => {
      name      = format("talos-wrkr-%d", index)
      node_type = "worker"
      id        = 1100 + index
      cores     = node.cores
      ram       = node.ram
      ip        = node.ip
      disk_size = node.disk_size
    }
  }
  all_nodes = merge(local.controlplanes, local.workers)
}