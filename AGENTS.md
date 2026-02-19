# AGENTS.md - Coding Agent Guidelines

This document provides guidelines for AI coding agents working in this homelab infrastructure repository.

## Repository Overview

This is a homelab infrastructure repository managing:
- **Terraform**: Proxmox VM provisioning with Talos OS (Kubernetes)
- **Helmfile**: Kubernetes deployments (Traefik, MetalLB)
- **Ansible**: Placeholder for future automation

## Build/Lint/Test Commands

### Terraform

```bash
cd terraform

terraform init
terraform plan
terraform apply
terraform destroy

terraform fmt -recursive
terraform validate
tflint

terraform plan -target=proxmox_virtual_environment_vm.vm["controlplanes0"]
terraform apply -target=proxmox_virtual_environment_vm.vm["worker0"]
```

### Helmfile

```bash
cd helm

helmfile lint
helmfile diff
helmfile apply
helmfile destroy

helmfile -l stage=infra apply
helmfile -l stage=config apply
helmfile -n traefik apply
```

### Individual Helm Chart Testing

```bash
helm template traefik traefik/traefik -f traefik/values.yaml --debug
helm lint metallb/
```

## Project Structure

```
├── terraform/
│   ├── main.tf              # Main resources (VMs, Talos images)
│   ├── providers.tf         # Provider configurations
│   ├── variables.tf         # Input variables
│   ├── build-*.tf           # Code generation (scripts, patches)
│   ├── vars/
│   │   ├── nodes.yaml       # Node definitions (controlplanes, workers)
│   │   └── network.yaml     # Network configuration
│   ├── templates/           # Terraform template files
│   └── files/               # Generated scripts (gitignored)
├── helm/
│   ├── helmfile.yaml        # Release definitions
│   ├── traefik/values.yaml  # Traefik configuration
│   └── metallb/             # MetalLB configuration
└── ansible/                 # Future automation
```

## Code Style Guidelines

### Terraform

- **Provider versions**: Pin versions in `providers.tf`
- **Variables**: Always include `description`, `type`, and mark sensitive with `sensitive = true`
- **Naming**: Use snake_case for resources and variables
- **Organization**: Split logical blocks into separate files (`build-*.tf`, `variables.tf`)
- **Templates**: Use `templatefile()` with `.tmpl` extension for generated scripts
- **Locals**: Group computed values in `locals` blocks in `build-node-list.tf`
- **For_each**: Prefer `for_each` over `count` for resource iteration
- **Comments**: Comment out resources rather than deleting during development

```hcl
variable "example" {
  description = "Purpose of this variable"
  type        = string
  sensitive   = true  # For secrets
}
```

### YAML (Helmfile, Config)

- **Indentation**: 2 spaces
- **Document start**: Use `---` at file beginning
- **Lists**: Use hyphen with space (`- item`)
- **Organization**: Group releases by stage with comments (`# --- STAGE: INFRA ---`)
- **Labels**: Use `stage` label to group deployments

### Shell Scripts

- **Shebang**: Always start with `#!/bin/bash`
- **Generated files**: These live in `terraform/files/` and are gitignored
- **Templates**: Edit `.tmpl` files, not generated scripts

### Naming Conventions

| Resource Type | Convention | Example |
|--------------|------------|---------|
| Terraform resources | snake_case | `proxmox_virtual_environment_vm` |
| Terraform locals | snake_case | `all_nodes`, `controlplanes` |
| YAML keys | snake_case | `disk_size`, `clustername` |
| VM names | hyphenated | `talos-ctrl-0`, `talos-wrkr-1` |
| Kubernetes namespaces | lowercase | `traefik`, `metallb-system` |
| Helm releases | lowercase | `metallb-config` |

## Error Handling

### Terraform

- Use `depends_on` for explicit dependencies
- Use `stop_on_destroy = true` for VMs
- Set `overwrite_unmanaged = true` for downloaded files

### Helmfile

- Use `needs` to specify dependency order between releases
- Use `createNamespace: true` for new namespaces

## Security Guidelines

- **Never commit**: `.tfvars` files, `terraform.tfstate`, `kubeconfig`, TLS certs
- **Sensitive variables**: Always mark with `sensitive = true`
- **Secrets in YAML**: Use `stringData` for Kubernetes secrets (but avoid in production)
- **Proxmox token**: Pass via environment variable or `.tfvars`

## Gitignore Patterns

```
.ansible
terraform/*.tfvars
terraform/.terraform*
terraform/terraform.tfstate*
files/
```

## Common Tasks

### Adding a new worker node

1. Edit `terraform/vars/nodes.yaml`:
```yaml
workers:
  - cores: 4
    ram: 16384
    ip: 192.168.2.103
    disk_size: 50
```

2. Run `terraform plan` and `terraform apply`

### Adding a new Helm release

1. Add repository to `helm/helmfile.yaml` if needed
2. Add release with appropriate `stage` label
3. Run `helmfile diff` to preview changes

### Updating Talos version

1. Update `terraform/variables.tf` default value
2. Run `terraform apply` to download new ISO
