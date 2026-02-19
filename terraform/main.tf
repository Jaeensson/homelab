data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = [
      "qemu-guest-agent",
      "i915",
      "intel-ucode"
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
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type        = "iso"
  datastore_id        = "local"
  node_name           = var.proxmox_node
  url                 = data.talos_image_factory_urls.this.urls.iso
  file_name           = "talos-${var.talos_version}-nocloud-amd64.iso"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each  = local.all_nodes
  name      = each.value.name
  node_name = var.proxmox_node
  vm_id     = each.value.id
  keyboard_layout = "sv"

  agent {
    enabled = true
  }

  boot_order = [
    "scsi0",
    "ide3"
  ]

  description = "Talos controlplane node - managed by Terraform"

  stop_on_destroy = true

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

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_iso.id
  }

  network_device {
    bridge = local.network.bridge
  }

  initialization {
    # meta_data_file_id = proxmox_virtual_environment_file.controlplane_user_data.id
    # vendor_data_file_id = proxmox_virtual_environment_file.controlplane_user_data.id

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

# resource "null_resource" "setup_nodes" {
#   depends_on = [
#     proxmox_virtual_environment_vm.vm,
#     local_file.nodes
#   ]
#   provisioner "local-exec" {
#     command = "bash ${path.module}/files/1st-setup-nodes.sh"
#   }
# }
# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [null_resource.setup_nodes]

#   create_duration = "60s"
# }


# resource "null_resource" "deploy_cluster" {
#   depends_on = [
#     null_resource.setup_nodes,
#     local_file.cluster,
#     time_sleep.wait_30_seconds
#   ]
#   provisioner "local-exec" {
#     command = "bash ${path.module}/files/2nd-deploy-cluster.sh"
#   }
# }
