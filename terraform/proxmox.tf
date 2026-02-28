data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = [
      "siderolabs/qemu-guest-agent",
      "siderolabs/i915",
      "siderolabs/intel-ucode",
      "siderolabs/iscsi-tools",
      "siderolabs/util-linux-tools"
    ]
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
  content_type        = "iso"
  datastore_id        = "local"
  node_name           = var.proxmox_node
  url                 = data.talos_image_factory_urls.this.urls.iso
  file_name           = "talos-${data.talos_image_factory_urls.this.talos_version}-${data.talos_image_factory_urls.this.platform}-${data.talos_image_factory_urls.this.architecture}.iso"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each        = local.all_nodes
  name            = each.value.name
  node_name       = var.proxmox_node
  vm_id           = each.value.id
  keyboard_layout = "sv"

  agent {
    enabled = true
  }

  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  description = "Talos controlplane node - managed by Terraform"

  operating_system {
    type = "l26"
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.ram
  }

  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  network_device {
    bridge = local.network.bridge
  }

  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_download_file.talos_image.id
    interface = "ide3"
  }

  boot_order = [
    "scsi0",
    "ide3"
  ]

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}${local.network.netmask}"
        gateway = local.network.gateway
      }
    }

    dns {
      domain  = "egenitres.se"
      servers = local.network.dns
    }

    datastore_id = "local-lvm"
  }
}