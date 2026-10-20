#!/usr/bin/env bash
# Fonctions communes aux scripts. Compatible bash 3.2 (macOS) et bash 5 (Linux, WSL2).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${PROFILE:-laptop}"

info() { printf '\033[34m[info]\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

# Variables qu'on peut forcer depuis l'environnement, par exemple :
#   REPO_URL=https://github.com/moi/ai-platform-lab.git make up
OVERRIDABLE_VARS="REPO_URL GITOPS_REVISION OLLAMA_ADDR OLLAMA_MODEL OLLAMA_PORT CLUSTER_NAME ARGOCD_REF ARGOCD_MANIFEST"

# Ordre de priorité : environnement > profiles/local.env > profiles/<profil>.env > profiles/common.env
load_profile() {
  local profile_file="$ROOT_DIR/profiles/${PROFILE}.env"
  if [[ ! -f "$profile_file" ]]; then
    local available="" f n
    for f in "$ROOT_DIR"/profiles/*.env; do
      n=$(basename "$f" .env)
      case "$n" in common|local) ;; *) available="$available $n" ;; esac
    done
    die "Profil inconnu : '$PROFILE'. Profils disponibles :$available"
  fi

  local overrides=() v
  for v in $OVERRIDABLE_VARS; do
    if [[ -n "${!v:-}" ]]; then overrides+=("$v=${!v}"); fi
  done

  set -a
  # shellcheck source=/dev/null
  source "$ROOT_DIR/profiles/common.env"
  # shellcheck source=/dev/null
  source "$profile_file"
  if [[ -f "$ROOT_DIR/profiles/local.env" ]]; then
    # shellcheck source=/dev/null
    source "$ROOT_DIR/profiles/local.env"
  fi
  set +a

  local kv
  for kv in ${overrides[@]+"${overrides[@]}"}; do export "${kv?}"; done
  export PROFILE
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Commande manquante : $1 ($2)"
}

kube() {
  kubectl --context "kind-${CLUSTER_NAME}" "$@"
}

cluster_exists() {
  kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

is_ipv4() {
  [[ "$1" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]
}
