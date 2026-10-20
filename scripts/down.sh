#!/usr/bin/env bash
# Supprime le cluster kind. Le code et la configuration restent dans Git.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_profile
require_cmd kind "https://kind.sigs.k8s.io"

if cluster_exists; then
  kind delete cluster --name "$CLUSTER_NAME"
  ok "Cluster '$CLUSTER_NAME' supprimé"
else
  info "Aucun cluster '$CLUSTER_NAME'"
fi
