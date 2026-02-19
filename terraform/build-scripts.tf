# This will generate the first Shell script, that will apply the config to the nodes based on their type
resource "local_file" "nodes" {
  content = templatefile("templates/setup.tmpl",
    {
      clustername   = local.network.clustername
      masterip      = local.controlplanes["controlplanes0"].ip
      controlplanes = local.controlplanes
      workers       = local.workers
    }
  )
  filename = "files/1st-setup-nodes.sh"
}

# This will generate the second script, that will bootstrap the cluster and create the kubeconfig file
resource "local_file" "cluster" {
  content = templatefile("templates/deploy.tmpl",
    {
      masterip = local.controlplanes["controlplanes0"].ip
    }
  )
  filename = "files/2nd-deploy-cluster.sh"
}