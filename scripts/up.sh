#!/usr/bin/env bash
# Crée (ou complète) la plateforme pour le profil choisi. Idempotent : relançable sans risque.
# Usage : PROFILE=laptop scripts/up.sh
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_profile

if [[ "${SKIP_PREFLIGHT:-0}" != "1" ]]; then
  "$ROOT_DIR/scripts/preflight.sh"
fi

require_cmd kind "https://kind.sigs.k8s.io"
require_cmd kubectl "https://kubernetes.io/docs/tasks/tools/"

# 1. Cluster kind
if cluster_exists; then
  info "Cluster '$CLUSTER_NAME' déjà présent, création ignorée"
else
  info "Création du cluster '$CLUSTER_NAME' ($KIND_CONFIG)"
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/$KIND_CONFIG"
fi
kube cluster-info >/dev/null
ok "Cluster joignable (contexte kind-$CLUSTER_NAME)"

# 2. Argo CD (commande issue de la documentation officielle "Getting Started")
info "Installation d'Argo CD ($ARGOCD_REF/$ARGOCD_MANIFEST)"
kube create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kube apply -f - >/dev/null
kube apply -n "$ARGOCD_NAMESPACE" --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_REF}/manifests/${ARGOCD_MANIFEST}" >/dev/null
info "Attente du démarrage d'Argo CD (quelques minutes au premier lancement)"
kube -n "$ARGOCD_NAMESPACE" rollout status deploy/argocd-repo-server --timeout=300s
kube -n "$ARGOCD_NAMESPACE" rollout status statefulset/argocd-application-controller --timeout=300s
if kube -n "$ARGOCD_NAMESPACE" get deploy/argocd-server >/dev/null 2>&1; then
  kube -n "$ARGOCD_NAMESPACE" rollout status deploy/argocd-server --timeout=300s
fi
ok "Argo CD prêt"

# 3. Backend LLM local : un Service sans sélecteur qui pointe vers Ollama, hors du cluster.
#    Cette ressource dépend de la machine (adresse IP) : elle n'est donc pas dans Git.
if [[ -z "${OLLAMA_ADDR:-}" ]]; then
  OLLAMA_ADDR=$(docker network inspect kind -f '{{range .IPAM.Config}}{{.Gateway}} {{end}}' 2>/dev/null \
    | tr ' ' '\n' | grep -E '^[0-9]+(\.[0-9]+){3}$' | head -1 || true)
fi
kube create namespace llm-backends --dry-run=client -o yaml | kube apply -f - >/dev/null
if [[ -z "${OLLAMA_ADDR:-}" ]]; then
  warn "Adresse d'Ollama introuvable : renseigne OLLAMA_ADDR dans profiles/local.env"
elif is_ipv4 "$OLLAMA_ADDR"; then
  kube apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: llm-backends
  labels:
    app.kubernetes.io/part-of: ai-platform-lab
spec:
  ports:
    - name: http
      port: ${OLLAMA_PORT}
      targetPort: ${OLLAMA_PORT}
      protocol: TCP
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: ollama-external
  namespace: llm-backends
  labels:
    kubernetes.io/service-name: ollama
    app.kubernetes.io/part-of: ai-platform-lab
addressType: IPv4
ports:
  - name: http
    port: ${OLLAMA_PORT}
    protocol: TCP
endpoints:
  - addresses: ["${OLLAMA_ADDR}"]
EOF
  ok "Service ollama.llm-backends -> ${OLLAMA_ADDR}:${OLLAMA_PORT}"
else
  # Nom DNS (autre machine du réseau, par exemple) : Service de type ExternalName.
  kube apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: llm-backends
  labels:
    app.kubernetes.io/part-of: ai-platform-lab
spec:
  type: ExternalName
  externalName: ${OLLAMA_ADDR}
  ports:
    - name: http
      port: ${OLLAMA_PORT}
EOF
  ok "Service ollama.llm-backends -> ${OLLAMA_ADDR} (ExternalName)"
fi

# 4. Application racine GitOps
if [[ -z "${REPO_URL:-}" ]]; then
  warn "REPO_URL vide : application racine non créée. Pousse le repo sur GitHub, renseigne profiles/local.env puis relance 'make up'."
else
  sed -e "s|\${ARGOCD_NAMESPACE}|${ARGOCD_NAMESPACE}|g" \
      -e "s|\${REPO_URL}|${REPO_URL}|g" \
      -e "s|\${GITOPS_REVISION}|${GITOPS_REVISION}|g" \
      -e "s|\${PROFILE}|${PROFILE}|g" \
      "$ROOT_DIR/gitops/bootstrap/root-app.yaml.tpl" | kube apply -f - >/dev/null
  ok "Application racine -> ${REPO_URL} @ ${GITOPS_REVISION} (gitops/profiles/${PROFILE})"
fi

cat <<EOF

Plateforme démarrée (profil $PROFILE).
  Interface Argo CD : kubectl --context kind-$CLUSTER_NAME -n $ARGOCD_NAMESPACE port-forward svc/argocd-server 8443:443
                      puis https://localhost:8443 (utilisateur admin)
  Mot de passe      : make argocd-password
  État              : make status
EOF
