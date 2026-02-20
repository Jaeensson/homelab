# AGENTS.md - Coding Agent Guidelines

This document provides guidelines for AI coding agents working in this homelab infrastructure repository.

## Repository Overview

This is a homelab infrastructure repository managing:
- **Terraform**: Proxmox VM provisioning with Talos OS (Kubernetes)
- **Helmfile**: Kubernetes deployments (Traefik, MetalLB, Infisical) with staged releases
- **SOPS**: Age-encrypted secrets for bootstrapping Infisical
- **Ansible**: Placeholder for future automation

## Build/Lint/Test Commands

### Makefile (Recommended)

```bash
make bootstrap      # Full deploy: terraform → talos → helmfile
make deploy         # Deploy/update helmfile releases
make clean          # Remove helm releases, namespaces & CRDs

# Terraform
make tf-init        make tf-plan        make tf-apply       make tf-destroy

# Talos
make talos-setup    make talos-bootstrap  make kubeconfig

# Helmfile (staged)
make helm-crds      make helm-infra     make helm-secrets    make helm-config    make helm-sync      make helm-apply     make helm-diff      make helm-destroy

# SOPS (secrets encryption)
make sops-keygen    make sops-encrypt   make sops-decrypt
```

### Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply -target=proxmox_virtual_environment_vm.vm["worker0"]
terraform fmt -recursive && terraform validate && tflint
```

### Helmfile

```bash
cd helm
helmfile -l stage=crds sync      # CRDs first (use sync, not apply)
helmfile -l stage=infra sync
helmfile -l stage=secrets sync   # Infisical + Operator (requires SOPS-decrypted secrets)
helmfile -l stage=config sync
helmfile apply                    # For updates after first install
```

> **Note**: Use `sync` for first-time installs. `apply` fails with helm-diff when CRDs don't exist yet.

### SOPS (Secrets Encryption)

```bash
# One-time setup
make sops-keygen              # Generate age key (backup to password manager!)
# Update .sops.yaml with your public key

# Encrypt bootstrap secrets
cd helm/infisical
# Edit secrets.yaml with your values
make sops-encrypt
rm secrets.yaml               # Delete plaintext after encrypting

# Decrypt for editing
make sops-decrypt
# Edit secrets.yaml
make sops-encrypt
rm secrets.yaml
```

### Individual Helm Chart Testing

```bash
helm template traefik traefik/traefik -f traefik/values.yaml --debug
```

## Project Structure

```
├── Makefile                 # Primary workflow commands
├── .sops.yaml               # SOPS encryption config
├── .sops.keys               # Age private key (gitignored, BACKUP!)
├── terraform/
│   ├── main.tf              # VM resources, Talos image factory
│   ├── providers.tf         # Provider configurations (pinned versions)
│   ├── variables.tf         # Input variables
│   ├── build-*.tf           # Code generation (scripts, patches)
│   ├── vars/
│   │   ├── nodes.yaml       # Node definitions (controlplanes, workers)
│   │   └── network.yaml     # Network configuration
│   ├── templates/           # .tmpl files for generated scripts
│   └── files/               # Generated scripts (gitignored)
├── helm/
│   ├── helmfile.yaml        # Releases organized by stage
│   ├── traefik/values.yaml
│   ├── metallb/metallb-conf.yaml
│   ├── infisical/
│   │   ├── values.yaml      # Infisical helm values
│   │   └── secrets.enc.yaml # SOPS-encrypted bootstrap secrets
│   └── secrets/             # InfisicalSecret CRDs
└── ansible/                 # Future automation
```

## Code Style Guidelines

### Terraform

- Pin provider versions in `providers.tf`
- Variables: include `description`, `type`, `sensitive = true` for secrets
- Use `for_each` over `count` for resource iteration
- Split logical blocks into separate files (`build-*.tf`)
- Use `templatefile()` with `.tmpl` extension for generated scripts
- Comment out resources during development rather than deleting

```hcl
variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}
```

### YAML (Helmfile, Config)

- 2-space indentation
- Use `---` at file beginning
- Group releases by `stage` label with comments
- Use `needs` for dependency ordering between releases
- Use `hooks` for post-install actions (e.g., namespace labeling)

```yaml
- name: metallb
  namespace: metallb-system
  labels:
    stage: infra
  hooks:
    - events: ["postsync"]
      command: "kubectl"
      args: ["label", "--overwrite", "namespace", "metallb-system", "pod-security.kubernetes.io/enforce=privileged"]
```

### Makefile

- Use `.PHONY` for all targets
- Group targets by category with comments
- Use variables for common paths (`TF_DIR`, `HELM_DIR`)

### Shell Scripts

- Always start with shebang: `#!/bin/bash`
- Generated files live in `terraform/files/` (gitignored)
- Edit `.tmpl` templates, not generated scripts

## Naming Conventions

| Resource Type | Convention | Example |
|--------------|------------|---------|
| Terraform resources | snake_case | `proxmox_virtual_environment_vm` |
| Terraform locals | snake_case | `all_nodes`, `controlplanes` |
| YAML keys | snake_case | `disk_size`, `clustername` |
| VM names | hyphenated | `talos-ctrl-0`, `talos-wrkr-1` |
| Kubernetes namespaces | lowercase | `traefik`, `metallb-system` |
| Helm releases | lowercase | `metallb-config` |
| Helmfile stages | lowercase | `crds`, `infra`, `secrets`, `config` |

## Security & Best Practices

- **Never commit**: `.tfvars`, `terraform.tfstate`, `kubeconfig`, TLS certs, `.sops.keys`, `secrets.yaml` (decrypted)
- **Sensitive variables**: Always mark with `sensitive = true`
- **MetalLB on Talos**: Requires `pod-security.kubernetes.io/enforce=privileged` label on namespace (handled by helmfile hook)
- **Helmfile dependencies**: Use `needs` to ensure proper install order (CRDs → Infra → Secrets → Config)
- **SOPS key backup**: Store `.sops.keys` in password manager - losing it means losing access to all encrypted secrets

## Common Tasks

### Add a worker node

Edit `terraform/vars/nodes.yaml` and run `make tf-apply`.

### Add a Helm release

Add to `helm/helmfile.yaml` with appropriate `stage` label and `needs` if dependencies exist.

### First-time cluster bootstrap

```bash
make bootstrap
```

### Update helmfile releases

```bash
make helm-sync    # or: make deploy
```

### Manage secrets

```bash
# First-time setup (one-time)
make sops-keygen
# Copy the public key output and update .sops.yaml

# Edit bootstrap secrets
make sops-decrypt
vim helm/infisical/secrets.yaml
make sops-encrypt
rm helm/infisical/secrets.yaml   # Never commit plaintext!

# Add application secrets via Infisical
# 1. Access Infisical UI at https://infisical.homelab.local
# 2. Create project, add secrets
# 3. Create machine identity for the operator
# 4. Add InfisicalSecret CRD in helm/secrets/
```
