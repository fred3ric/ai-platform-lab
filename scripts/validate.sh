#!/usr/bin/env bash
# Validation statique, sans cluster : scripts shell et manifestes rendus par Kustomize.
# Utilisé en local (make validate) et en CI.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

status=0

if command -v shellcheck >/dev/null 2>&1; then
  info "shellcheck"
  shellcheck -x "$ROOT_DIR"/scripts/*.sh && ok "Scripts shell conformes" || status=1
else
  warn "shellcheck absent, vérification des scripts ignorée"
fi

if command -v kubectl >/dev/null 2>&1; then
  render() { kubectl kustomize "$1"; }
elif command -v kustomize >/dev/null 2>&1; then
  render() { kustomize build "$1"; }
else
  die "kubectl ou kustomize requis pour rendre les manifestes"
fi
require_cmd kubeconform "https://github.com/yannh/kubeconform"

for dir in "$ROOT_DIR"/gitops/profiles/*/; do
  name=$(basename "$dir")
  info "Profil GitOps '$name'"
  if render "$dir" | kubeconform -strict -summary -ignore-missing-schemas; then
    ok "gitops/profiles/$name valide"
  else
    status=1
  fi
done

exit "$status"
