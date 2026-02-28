data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = concat(["siderolabs/qemu-guest-agent"], var.talos_extensions)
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
  architecture  = "amd64"
}

resource "proxmox_virtual_environment_download_file" "talos_image" {
  for_each            = local.all_proxmox_nodes
  content_type        = "iso"
  datastore_id        = "local"
  node_name           = each.value
  url                 = data.talos_image_factory_urls.this.urls.iso
  file_name           = "talos-${data.talos_image_factory_urls.this.talos_version}-${data.talos_image_factory_urls.this.platform}-${data.talos_image_factory_urls.this.architecture}.iso"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "vm" {
  count           = length(local.all_nodes)
  name            = local.all_nodes[count.index].node_name
  node_name       = local.all_nodes[count.index].proxmox_node
  vm_id           = local.all_nodes[count.index].vm_id
  keyboard_layout = "sv"

  agent {
    enabled = true
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  description = "Talos vm - managed by Terraform"

  operating_system {
    type = "l26"
  }

  cpu {
    cores = local.all_nodes[count.index].cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = local.all_nodes[count.index].ram_mb
  }

  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    size         = local.all_nodes[count.index].disk_size_gb
  }

  network_device {
    bridge = var.network_bridge
  }

  cdrom {
    file_id   = proxmox_virtual_environment_download_file.talos_image[local.all_nodes[count.index].proxmox_node].id
    interface = "ide3"
  }

  boot_order = [
    "scsi0",
    "ide3"
  ]

  initialization {
    ip_config {
      ipv4 {
        address = "${local.all_nodes[count.index].ip}${var.network_netmask}"
        gateway = var.network_gateway
      }
    }

    dns {
      domain  = "egenitres.se"
      servers = var.network_dns
    }

    datastore_id = "local-lvm"
  }
}