# This will generate the first Shell script, that will apply the config to the nodes based on their type
resource "local_file" "network_patches" {
  for_each = local.all_nodes
  content = templatefile("templates/network-patch.yaml.tmpl",
    {
      name    = each.value.name
      ip      = each.value.ip
      netmask = local.network.netmask
      gateway = local.network.gateway
      dns     = local.network.dns
      network = local.network.network
    }
  )
  filename = "files/patch-${each.value.name}.yaml"
}