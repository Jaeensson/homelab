# AGENTS.md

## Project overview

This is the infrastructure project for my home lab. While currently not finished there are some overall guide lines to be considered.

### General guidelines
This is an automation project, no user interaction other than applying changes through terraform and ansible should be required unless strictly required.

See [TODO.md](./TODO.md) for the current work orders

See the external_examples folder for examples provided by external services

Ask the user for any missing credentials

## Infrasrtructure
### Networking
- Subnet: `192.168.0.0/22`
- Gateway: `192.168.1.1`
- DNS: `192.168.1.21`

All addresses in the space `192.168.2.0/24` are reserved for this project.

All virutal machines should have statically assigned IP addresses assigned.


## Terraform

### Running 
- Initialize backend: `terraform init`
- Plan changes: `terraform plan`
- Apply changes: `terraform apply`
- Validate configuration: `terraform validate`
- Format code: `terraform fmt -recursive`

### Code style

- Use 2 spaces for indentation in `.tf` files
- Use lowercase with underscores for resource names: `module.virtual_machine`, `var.proxmox_url`
- Group related resources using locals blocks
- Always add descriptive comments for complex configurations
- Use variables for all environment-specific values

### Folder structure

- `modules/` - Reusable Terraform modules (proxmox_vms, lxc_container)
- `templates/` - Template files that may be of use, such as cloud-init configuration files

### Terraform conventions

- **Variables**: Define in `variables.tf`, never hardcode sensitive values
- **Modules**: Create reusable modules for common patterns (e.g., lxc_container)
- **Version pinning**: Pin provider versions for reproducibility

## Security
- Never commit secrets, passwords, or API keys

### Storage
- Locally stored secrets are permitted during development
- Target is to fetch all secrets from Bitwarden

## Ansible
TBD