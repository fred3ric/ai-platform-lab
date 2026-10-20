#!/usr/bin/env bash
# Affiche l'état de la plateforme.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_profile

cluster_exists || die "Aucun cluster '$CLUSTER_NAME'. Lancer : make up PROFILE=$PROFILE"

echo "== Nœuds"
kube get nodes -o wide
echo
echo "== Applications Argo CD"
kube -n "$ARGOCD_NAMESPACE" get applications.argoproj.io 2>/dev/null || echo "(aucune)"
echo
echo "== Pods non prêts"
kube get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null || true
echo
echo "== Consommation mémoire des conteneurs kind"
ids=$(docker ps --filter "label=io.x-k8s.kind.cluster=${CLUSTER_NAME}" -q)
if [[ -n "$ids" ]]; then
  # shellcheck disable=SC2086 # une liste d'identifiants, découpage voulu
  docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' $ids
fi
