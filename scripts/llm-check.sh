#!/usr/bin/env bash
# Vérifie depuis l'intérieur du cluster que le backend LLM (Ollama) répond.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_profile

cluster_exists || die "Aucun cluster '$CLUSTER_NAME'. Lancer : make up PROFILE=$PROFILE"

info "Appel de http://ollama.llm-backends:${OLLAMA_PORT}/api/tags depuis un pod"
if kube -n llm-backends run "llm-check-$$" --rm -i --restart=Never --quiet \
    --image=curlimages/curl:8.10.1 -- \
    curl -fsS --max-time 10 "http://ollama.llm-backends:${OLLAMA_PORT}/api/tags"; then
  echo
  ok "Le cluster joint Ollama"
else
  die "Ollama injoignable depuis le cluster. Vérifier OLLAMA_HOST=0.0.0.0 (docs/WSL2.md) et OLLAMA_ADDR."
fi
