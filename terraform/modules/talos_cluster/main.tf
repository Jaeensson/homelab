locals {
  cluster_endpoint = "https://${var.controlplane_ip}:6443"

  worker_count = length(var.worker_ips)

  controlplane_network_config = <<-EOT
machine:
  network:
    interfaces:
      - interface: eth0
        dhcp: false
        addresses:
          - ${var.controlplane_ip}/22
        routes:
          - gateway: ${var.gateway}
            network: 192.168.0.0/22
    nameservers:
      - ${join("\n      - ", var.dns_servers)}
EOT

  worker_network_config = {
    for ip in var.worker_ips :
    ip => <<-EOT
machine:
  network:
    interfaces:
      - interface: eth0
        dhcp: false
        addresses:
          - ${ip}/22
        routes:
          - gateway: ${var.gateway}
            network: 192.168.0.0/22
    nameservers:
      - ${join("\n      - ", var.dns_servers)}
EOT
  }
}

resource "talos_image_factory_schematic" "this" {}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type        = "iso"
  datastore_id        = "local"
  node_name           = var.proxmox_node
  url                 = data.talos_image_factory_urls.this.urls.iso
  file_name           = "talos-${var.talos_version}-nocloud-amd64.iso"
  overwrite_unmanaged = true
}

resource "talos_machine_secrets" "this" {
  talos_version = "v${var.talos_version}"
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches   = [local.controlplane_network_config]
}

data "talos_machine_configuration" "worker" {
  for_each         = toset(var.worker_ips)
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches   = [local.worker_network_config[each.value]]
}

resource "proxmox_virtual_environment_file" "controlplane_user_data" {
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_storage
  node_name    = var.proxmox_node

  source_raw {
    data      = data.talos_machine_configuration.controlplane.machine_configuration
    file_name = "user-data-controlplane.yaml"
  }
}

resource "proxmox_virtual_environment_file" "controlplane_meta_data" {
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_storage
  node_name    = var.proxmox_node

  source_raw {
    data      = <<-EOT
local-hostname: ${var.cluster_name}-controlplane-1
EOT
    file_name = "meta-data-controlplane.yaml"
  }
}

resource "proxmox_virtual_environment_file" "worker_user_data" {
  for_each     = toset(var.worker_ips)
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_storage
  node_name    = var.proxmox_node

  source_raw {
    data      = data.talos_machine_configuration.worker[each.value].machine_configuration
    file_name = "user-data-worker-${replace(each.value, ".", "-")}.yaml"
  }
}

resource "proxmox_virtual_environment_file" "worker_meta_data" {
  for_each     = toset(var.worker_ips)
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_storage
  node_name    = var.proxmox_node

  source_raw {
    data      = <<-EOT
local-hostname: ${var.cluster_name}-worker-${index(var.worker_ips, each.value) + 1}
EOT
    file_name = "meta-data-worker-${replace(each.value, ".", "-")}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "controlplane" {
  name      = "${var.cluster_name}-controlplane-1"
  node_name = var.proxmox_node
  vm_id     = var.controlplane_vm_id

  description = "Talos controlplane node - managed by Terraform"

  stop_on_destroy = true

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.vm_cpu
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = var.proxmox_storage
    interface    = "virtio0"
    size         = var.vm_disk_size
  }

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_iso.id
  }

  network_device {
    bridge = var.vm_network_bridge
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.controlplane_user_data.id
    meta_data_file_id = proxmox_virtual_environment_file.controlplane_meta_data.id
  }
}

resource "proxmox_virtual_environment_vm" "workers" {
  count     = local.worker_count
  name      = "${var.cluster_name}-worker-${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = var.worker_vm_ids[count.index]

  description = "Talos worker node - managed by Terraform"

  stop_on_destroy = true

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.vm_cpu
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = var.proxmox_storage
    interface    = "virtio0"
    size         = var.vm_disk_size
  }

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_iso.id
  }

  network_device {
    bridge = var.vm_network_bridge
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.worker_user_data[var.worker_ips[count.index]].id
    meta_data_file_id = proxmox_virtual_environment_file.worker_meta_data[var.worker_ips[count.index]].id
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    proxmox_virtual_environment_vm.controlplane,
    proxmox_virtual_environment_vm.workers
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.controlplane_ip
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.controlplane_ip
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = concat([var.controlplane_ip], var.worker_ips)
}
