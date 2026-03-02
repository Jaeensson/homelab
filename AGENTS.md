# AGENTS.md - Homelab Infrastructure Repository

This is a Kubernetes/Terraform homelab infrastructure repository using Flux for GitOps, deployed on Talos Linux via Proxmox.

## Repository Structure

```
.
├── .justfile              # Root justfile with deploy command
├── .env                   # Environment variables (secrets)
├── kubernetes/            # Kubernetes manifests and Flux configuration
│   ├── apps/              # Application manifests (flux-system, infisical-system)
│   ├── bootstrap/         # Bootstrap resources and helmfiles
│   └── flux/              # Flux Kustomizations
└── terraform/             # Terraform for Proxmox + Talos cluster
    ├── modules/           # Terraform modules
    └── vars/              # Variable definitions
```

## Build/Lint/Test Commands

This repository uses **just** for task automation. No traditional unit tests exist.

### Just Commands

```bash
# Full deployment (Terraform + Kubernetes)
just deploy

# Terraform operations
just terraform::apply              # Apply Terraform changes
just terraform::destroy            # Destroy infrastructure
just terraform::get-config         # Get kubeconfig and talosconfig

# Kubernetes operations
just k8s::wait                     # Wait for nodes to be ready
just k8s::namespaces               # Apply namespace resources
just k8s::crds                     # Apply CRDs
just k8s::resources               # Apply bootstrap resources
just k8s::apps                     # Sync all apps via helmfile
just k8s::apply-ks <ns> <ks>       # Apply a specific Kustomization
just k8s::prune-pods              # Delete pods in Failed/Pending/Succeeded phases
```

### Terraform Commands (run from terraform/ directory)

```bash
cd terraform
terraform init                    # Initialize providers
terraform validate               # Validate Terraform syntax
terraform plan                    # Show planned changes
terraform apply                   # Apply changes
terraform destroy                 # Destroy resources
```

### YAML Formatting/Linting

This project uses **yamlfmt** for YAML validation.

```bash
# Check YAML formatting (from terraform/ directory)
yamlfmt -c terraform/.yamlfmt.yaml check .

# Format YAML files
yamlfmt -c terraform/.yamlfmt.yaml -w .
```

**Configuration**: See `terraform/.yamlfmt.yaml` for formatting rules (basic formatter, block array style, LF line endings).

## Code Style Guidelines

### General Principles

1. **GitOps-first**: All changes should be declarative and version-controlled
2. **Idempotency**: Resources should be idempotent (safe to reapply)
3. **Separation of concerns**: Bootstrap resources separate from app resources
4. **Sensitive data**: Never commit secrets; use Infisical Secrets Operator

### YAML Conventions

- **File naming**: kebab-case (`helmrelease.yaml`, `kustomization.yaml`, `infisicalsecret.yaml`)
- **Indentation**: 2 spaces
- **Document separators**: Use `---` at start of each YAML document
- **Block style arrays**: Use block style for multi-line arrays (configured in yamlfmt)
- **Include document start**: Always include `---` at start of files
- **Schema annotations**: Include YAML schema for IDE support

### Terraform Conventions

- **File naming**: snake_case (`main.tf`, `variables.tf`, `providers.tf`)
- **Variable naming**: snake_case, descriptive names
- **Sensitive values**: Mark sensitive variables with `sensitive = true`
- **Provider locking**: Use `.terraform.lock.hcl` for provider versioning

### Kubernetes/Flux Conventions

- **Namespace structure**: `apps/<namespace>/<app>/`
- **Kustomization layers**: `ks.yaml` (app level), `app/kustomization.yaml`, `app/helmrelease.yaml`
- **Default policies** (set in cluster ks.yaml):
  - `deletionPolicy: WaitForTermination`
  - HelmRelease: `install.crds: CreateReplace`, `upgrade.crds: CreateReplace`
  - HelmRelease remediation: `remediateLastFailure: true`, `retries: 2`

### Error Handling

- **Fail fast**: Use `set -euo pipefail` in bash scripts
- **Graceful degradation**: Use `&>/dev/null` for optional checks
- **Validation**: Validate before apply with `yq ea -e`

### Naming Conventions

| Resource Type | Convention | Example |
|---------------|------------|---------|
| Files (YAML) | kebab-case | `helmrelease.yaml` |
| Files (TF) | snake_case | `main.tf` |
| Variables | snake_case | `proxmox_endpoint` |
| Kubernetes objects | kebab-case | `infisical-system` |
| Namespaces | kebab-case | `flux-system` |

### Common Patterns

**Adding a new application:**
1. Create directory: `kubernetes/apps/<namespace>/<app>/`
2. Add `namespace.yaml` for the namespace
3. Add `ks.yaml` for Kustomization
4. Add `app/` subdirectory with `kustomization.yaml` and `helmrelease.yaml`
5. Add to appropriate helmfile in `kubernetes/bootstrap/helmfile.d/`

**Updating a Helm release:**
1. Edit `app/helmrelease.yaml` - update `spec.chartRef` or `spec.values`
2. Run `just k8s::apps` to sync changes
3. Verify with `kubectl get hr -A`

### Environment Variables

- **`.env`**: Contains local secrets (Proxmox credentials, etc.) - never commit
- **`example.env`**: Template for required environment variables
- **`.env` loading**: Enabled via `set dotenv-load := true` in justfiles

### Pre-Deployment Checklist

Before running `just deploy`:
1. Review Terraform changes with `cd terraform && terraform plan`
2. Validate YAML with `yamlfmt -c terraform/.yamlfmt.yaml check .`
3. Verify `.env` has required variables
4. Backup state if needed (`terraform.tfstate.backup`)

### Useful Debug Commands

```bash
# Check Flux reconciliation
flux get ks -A
flux get hr -A

# Check Helm releases status
kubectl get hr -A -o wide

# View Flux logs
kubectl logs -n flux-system deploy/source-controller
kubectl logs -n flux-system deploy/helm-controller

# Terraform debug
TF_LOG=DEBUG terraform apply
```
