resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = local.network.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for node in local.all_nodes : node.ip]
  endpoints            = [local.controlplanes["controlplanes0"].ip]
}

data "talos_machine_configuration" "this" {
  for_each         = local.all_nodes
  cluster_name     = local.network.cluster_name
  machine_type     = each.value.node_type
  cluster_endpoint = "https://${local.controlplanes["controlplanes0"].ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = [
    templatefile("./templates/install-patch.yaml.tftpl", {
      dns       = local.network.dns
      ip        = each.value.ip
      netmask   = local.network.netmask
      gateway   = local.network.gateway
      node_name = each.value.name
      image     = data.talos_image_factory_urls.this.urls.installer
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  for_each                    = local.all_nodes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  node                        = each.value.ip
  config_patches              = data.talos_machine_configuration.this[each.key].config_patches
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.this
  ]
  node                 = local.controlplanes["controlplanes0"].ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  node                 = local.controlplanes["controlplanes0"].ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}