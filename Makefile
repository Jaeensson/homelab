SHELL := bash
.DEFAULT_GOAL := help

TF_DIR := terraform
HELM_DIR := helm
TALOSCONFIG := $(TF_DIR)/files/talosconfig
KUBECONFIG ?= $(TF_DIR)/files/kubeconfig
SOPS_AGE_KEY_FILE := .sops.keys

.PHONY: help
help:
	@echo "🏠 Homelab Infrastructure Management"
	@echo ""
	@echo "🚀 Main workflows:"
	@echo "  make bootstrap      Full deploy: terraform → talos → helmfile"
	@echo "  make deploy         Deploy/update helmfile releases"
	@echo ""
	@echo "🏗️  Terraform:"
	@echo "  make tf-init        Initialize terraform"
	@echo "  make tf-plan        Plan terraform changes"
	@echo "  make tf-apply       Apply terraform (creates VMs, generates scripts)"
	@echo "  make tf-destroy     Destroy terraform resources"
	@echo ""
	@echo "⚙️  Talos/Kubernetes:"
	@echo "  make talos-setup    Apply Talos config to nodes (1st script)"
	@echo "  make talos-bootstrap Bootstrap cluster & get kubeconfig (2nd script)"
	@echo "  make kubeconfig     Re-export kubeconfig from talos"
	@echo ""
	@echo "⛵ Helmfile:"
	@echo "  make helm-crds      Install CRDs stage"
	@echo "  make helm-infra     Install infra stage"
	@echo "  make helm-secrets   Install secrets stage (Infisical)"
	@echo "  make helm-config    Install config stage"
	@echo "  make helm-sync      Sync all stages in order"
	@echo "  make helm-apply     Apply all (for updates)"
	@echo "  make helm-diff      Show pending changes"
	@echo "  make helm-destroy   Remove all helm releases"
	@echo ""
	@echo "🔐 SOPS (Secrets encryption):"
	@echo "  make sops-keygen    Generate age key for SOPS encryption"
	@echo "  make sops-encrypt   Encrypt infisical secrets.yaml"
	@echo "  make sops-decrypt   Decrypt infisical secrets.enc.yaml"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean          Remove helm releases, namespaces & CRDs"
	@echo ""

.PHONY: bootstrap
bootstrap: tf-apply talos-setup talos-bootstrap helm-sync
	@echo "✅ Bootstrap complete!"

.PHONY: deploy
deploy: helm-sync

# Terraform targets
.PHONY: tf-init
tf-init:
	cd $(TF_DIR) && terraform init

.PHONY: tf-plan
tf-plan:
	cd $(TF_DIR) && terraform plan

.PHONY: tf-apply
tf-apply:
	cd $(TF_DIR) && terraform apply -auto-approve

.PHONY: tf-destroy
tf-destroy:
	cd $(TF_DIR) && terraform destroy

# Talos targets
.PHONY: talos-setup
talos-setup:
	@echo "🔧 Applying Talos config to nodes..."
	cd $(TF_DIR) && bash files/1st-setup-nodes.sh

.PHONY: talos-bootstrap
talos-bootstrap:
	@echo "🚀 Bootstrapping Talos cluster..."
	cd $(TF_DIR) && bash files/2nd-deploy-cluster.sh

.PHONY: kubeconfig
kubeconfig:
	cd $(TF_DIR) && TALOSCONFIG=$(TALOSCONFIG) talosctl kubeconfig ./files

# Helmfile targets
.PHONY: helm-crds
helm-crds:
	cd $(HELM_DIR) && helmfile -l stage=crds sync

.PHONY: helm-infra
helm-infra:
	cd $(HELM_DIR) && helmfile -l stage=infra sync

.PHONY: helm-secrets
helm-secrets:
	@if [ ! -f $(HELM_DIR)/infisical/secrets.yaml ]; then \
		echo "🔐 Decrypting secrets..."; \
		SOPS_AGE_KEY=$(SOPS_AGE_KEY_FILE) sops -d $(HELM_DIR)/infisical/secrets.enc.yaml > $(HELM_DIR)/infisical/secrets.yaml; \
	fi
	@echo "⏳ Waiting for Infisical to be ready..."
	@for i in $$(seq 1 60); do \
		if kubectl get pods -n infisical -l app.kubernetes.io/name=infisical -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q "True"; then \
			echo "✅ Infisical ready"; \
			break; \
		fi; \
		echo "⏳ Waiting for Infisical... ($$i/60)"; \
		sleep 2; \
	done
	cd $(HELM_DIR) && helmfile -l stage=secrets sync
	@rm -f $(HELM_DIR)/infisical/secrets.yaml

.PHONY: helm-config
helm-config:
	@echo "⏳ Waiting for MetalLB webhook to be ready..."
	@for i in $$(seq 1 30); do \
		if kubectl get pods -n metallb-system -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q "True"; then \
			echo "✅ MetalLB controller ready"; \
			break; \
		fi; \
		echo "⏳ Waiting for MetalLB controller... ($$i/30)"; \
		sleep 2; \
	done
	cd $(HELM_DIR) && helmfile -l stage=config sync

.PHONY: helm-sync
helm-sync: helm-crds helm-infra helm-secrets helm-config
	@echo "✅ All helmfile releases synced!"

.PHONY: helm-apply
helm-apply:
	cd $(HELM_DIR) && helmfile apply

.PHONY: helm-diff
helm-diff:
	cd $(HELM_DIR) && helmfile diff

.PHONY: helm-destroy
helm-destroy:
	cd $(HELM_DIR) && helmfile destroy

# Cleanup targets
.PHONY: clean
clean: helm-destroy
	@echo "🗑️  Deleting namespaces..."
	kubectl delete namespace traefik --ignore-not-found=true || true
	kubectl delete namespace metallb-system --ignore-not-found=true || true
	kubectl delete namespace infisical --ignore-not-found=true || true
	kubectl delete namespace infisical-operator-system --ignore-not-found=true || true
	@echo "🗑️  Deleting CRDs..."
	@crds=$$(kubectl get crd -o name | grep -E '(traefik|gateway|metallb|infisical)' 2>/dev/null); \
	if [ -n "$$crds" ]; then \
		echo "$$crds" | xargs kubectl delete; \
	fi
	@rm -f $(HELM_DIR)/infisical/secrets.yaml
	@echo "✅ Cleanup complete!"

# SOPS targets
.PHONY: sops-keygen
sops-keygen:
	@if [ -f $(SOPS_AGE_KEY_FILE) ]; then \
		echo "⚠️  Key file already exists: $(SOPS_AGE_KEY_FILE)"; \
		echo "To regenerate, delete the existing file first."; \
		exit 1; \
	fi
	@age-keygen -o $(SOPS_AGE_KEY_FILE) 2>&1 | tee /dev/stderr | grep "public key:" | sed 's/.*public key: //' > /tmp/age-pub.tmp
	@echo ""
	@echo "✅ Age key generated at $(SOPS_AGE_KEY_FILE)"
	@echo ""
	@echo "📋 Your public key:"
	@cat /tmp/age-pub.tmp
	@echo ""
	@echo "⚠️  Next steps:"
	@echo "   1. Copy the public key above"
	@echo "   2. Update .sops.yaml with your public key"
	@echo "   3. BACKUP $(SOPS_AGE_KEY_FILE) to your password manager!"
	@rm -f /tmp/age-pub.tmp

.PHONY: sops-encrypt
sops-encrypt:
	@if [ ! -f $(SOPS_AGE_KEY_FILE) ]; then \
		echo "❌ No age key found. Run 'make sops-keygen' first."; \
		exit 1; \
	fi
	@if [ ! -f $(HELM_DIR)/infisical/secrets.yaml ]; then \
		echo "❌ No plaintext secrets.yaml found. Create it first."; \
		exit 1; \
	fi
	SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) sops -e $(HELM_DIR)/infisical/secrets.yaml > $(HELM_DIR)/infisical/secrets.enc.yaml
	@echo "✅ Encrypted to $(HELM_DIR)/infisical/secrets.enc.yaml"
	@echo "⚠️  Verify encryption, then delete the plaintext file:"
	@echo "   rm $(HELM_DIR)/infisical/secrets.yaml"

.PHONY: sops-decrypt
sops-decrypt:
	@if [ ! -f $(SOPS_AGE_KEY_FILE) ]; then \
		echo "❌ No age key found. Restore from backup or run 'make sops-keygen'."; \
		exit 1; \
	fi
	SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) sops -d $(HELM_DIR)/infisical/secrets.enc.yaml > $(HELM_DIR)/infisical/secrets.yaml
	@echo "✅ Decrypted to $(HELM_DIR)/infisical/secrets.yaml"
	@echo "⚠️  Remember to delete after editing:"
