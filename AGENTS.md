# AGENTS.md

## Project overview

This is the infrastructure project for my home lab

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