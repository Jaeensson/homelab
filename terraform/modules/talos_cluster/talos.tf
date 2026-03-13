resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for node in local.all_nodes : node.ip]
  endpoints            = [var.cluster_endpoint]
}

data "talos_machine_configuration" "this" {
  count            = length(local.all_nodes)
  cluster_name     = var.cluster_name
  machine_type     = local.all_nodes[count.index].node_type
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = [
    templatefile("${path.module}/templates/install-patch.yaml.tftpl", {
      dns       = var.network_dns
      ip        = local.all_nodes[count.index].ip
      netmask   = var.network_netmask
      gateway   = var.network_gateway
      node_name = local.all_nodes[count.index].node_name
      node_type = local.all_nodes[count.index].node_type
      image     = data.talos_image_factory_urls.this.urls.installer
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  count                       = length(local.all_nodes)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[count.index].machine_configuration
  node                        = local.all_nodes[count.index].ip
  config_patches              = data.talos_machine_configuration.this[count.index].config_patches
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.this
  ]
  node                 = var.cluster_endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  node                 = var.cluster_endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
}

