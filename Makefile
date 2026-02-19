SHELL := bash
.DEFAULT_GOAL := help

TF_DIR := terraform
HELM_DIR := helm
TALOSCONFIG := $(TF_DIR)/files/talosconfig
KUBECONFIG ?= $(TF_DIR)/files/kubeconfig

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
	@echo "  make helm-config    Install config stage"
	@echo "  make helm-sync      Sync all stages in order"
	@echo "  make helm-apply     Apply all (for updates)"
	@echo "  make helm-diff      Show pending changes"
	@echo "  make helm-destroy   Remove all helm releases"
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
helm-sync: helm-crds helm-infra helm-config
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
	@echo "🗑️  Deleting CRDs..."
	@crds=$$(kubectl get crd -o name | grep -E '(traefik|gateway|metallb)' 2>/dev/null); \
	if [ -n "$$crds" ]; then \
		echo "$$crds" | xargs kubectl delete; \
	fi
	@echo "✅ Cleanup complete!"
