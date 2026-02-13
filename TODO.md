# TODO.md

## Terraform modules
- Create a first module for setting up the k8s cluster on talos os.
  - Use the provider **bpg/proxmox** to set up the virtual machines
  - Use the provider **siderolabs/talos**
  - The cluster should consist of 1 control plane node and 2 worker nodes

- Use talos nocloud images and cloud-init for the k8s nodes

