terraform {
  required_providers {
    # infisical = {
    #   source  = "Infisical/infisical"
    #   version = "0.16.4"
    # }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.95.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
  }
}

# provider "infisical" {
#   host = "https://eu.infisical.com"
#   auth = {
#     universal = {
#       client_id     = var.infisical_client_id
#       client_secret = var.infisical_client_secret
#     }
#   }
# }

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_token

  ssh {
    username = "root"
    agent    = true
  }

  insecure = true
}

provider "talos" {
}
