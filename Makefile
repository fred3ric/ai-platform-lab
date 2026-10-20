SHELL := /bin/bash
.DEFAULT_GOAL := help

# Profil de machine : laptop (par défaut) ou workstation. Exemple : make up PROFILE=workstation
PROFILE ?= laptop
export PROFILE

.PHONY: help preflight up down status llm-check validate argocd-password argocd-ui

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Profil courant : $(PROFILE)"

preflight: ## Vérifie que la machine peut faire tourner le profil
	@scripts/preflight.sh

up: ## Crée le cluster, installe Argo CD, branche Ollama et le GitOps (idempotent)
	@scripts/up.sh

down: ## Supprime le cluster (le repo reste intact)
	@scripts/down.sh

status: ## État des nœuds, des applications et de la mémoire
	@scripts/status.sh

llm-check: ## Vérifie que le cluster joint Ollama
	@scripts/llm-check.sh

validate: ## Validation statique (shellcheck, kustomize, kubeconform)
	@scripts/validate.sh

argocd-password: ## Affiche le mot de passe admin initial d'Argo CD
	@source scripts/lib.sh && load_profile && \
	  kube -n "$$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

argocd-ui: ## Ouvre un tunnel vers l'interface Argo CD (https://localhost:8443)
	@source scripts/lib.sh && load_profile && \
	  kube -n "$$ARGOCD_NAMESPACE" port-forward svc/argocd-server 8443:443
