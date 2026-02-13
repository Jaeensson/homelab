terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~>0.95.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
  }
}

provider "proxmox" {
  endpoint  = "TBD"
  api_token = "TBD"
  insecure  = true
}

provider "talos" {}