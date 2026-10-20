#!/usr/bin/env bash
# Vérifie que la machine peut faire tourner le profil choisi.
# Usage : PROFILE=laptop scripts/preflight.sh
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_profile

errors=0
fail() { printf '\033[31m[fail]\033[0m %s\n' "$*" >&2; errors=$((errors + 1)); }

info "Profil : $PROFILE ($KIND_CONFIG)"

# 1. Outils
for c in docker kind kubectl git curl; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c présent"; else fail "$c absent (voir README, section Prérequis)"; fi
done

# 2. Démon Docker
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then ok "Démon Docker joignable"; else fail "Démon Docker injoignable (sudo service docker start, ou droits du groupe docker)"; fi
fi

# 3. Mémoire vue par Docker (sur WSL2, c'est le plafond du .wslconfig)
ram_mb=""
if [[ -r /proc/meminfo ]]; then
  ram_mb=$(awk '/^MemTotal:/ {printf "%d", $2/1024}' /proc/meminfo)
elif [[ "$(uname)" == "Darwin" ]]; then
  ram_mb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 ))
  warn "macOS : la limite réelle est la mémoire allouée à la VM Docker, pas la RAM de la machine."
fi
if [[ -n "$ram_mb" ]]; then
  if (( ram_mb >= MIN_RAM_MB )); then ok "Mémoire : ${ram_mb} Mo (minimum ${MIN_RAM_MB})"
  else fail "Mémoire : ${ram_mb} Mo, minimum ${MIN_RAM_MB} pour le profil $PROFILE"; fi
fi

# 4. Disque libre sur la partition du repo
disk_gb=$(df -Pk "$ROOT_DIR" | awk 'NR==2 {printf "%d", $4/1024/1024}')
if (( disk_gb >= MIN_DISK_GB )); then ok "Disque libre : ${disk_gb} Go (minimum ${MIN_DISK_GB})"
else fail "Disque libre : ${disk_gb} Go, minimum ${MIN_DISK_GB}. Essayer : docker system prune"; fi

# 5. cgroup v2 : les versions récentes du kubelet refusent de démarrer sur un hôte cgroup v1.
#    Le nœud kind hérite des cgroups de l'hôte Docker.
if [[ "$(uname)" == "Linux" ]]; then
  cg=$(stat -fc %T /sys/fs/cgroup/ 2>/dev/null || echo inconnu)
  if [[ "$cg" == "cgroup2fs" ]]; then ok "cgroup v2 actif"
  elif is_wsl; then fail "cgroup v1 détecté ($cg) : kind ne démarrera pas. Voir docs/WSL2.md, section cgroup v2"
  else fail "cgroup v1 détecté ($cg) : kind ne démarrera pas. Passer l'hôte en cgroup v2"; fi
fi

# 6. Contexte WSL2
if is_wsl; then
  ok "WSL2 détecté"
  case "$ROOT_DIR" in
    /mnt/*) warn "Le repo est sur le disque Windows ($ROOT_DIR) : performances dégradées. Clone-le dans ~ côté WSL." ;;
  esac
fi

# 7. GPU (informatif)
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1 || true)
  if [[ -n "$gpu" ]]; then ok "GPU : $gpu"; else warn "nvidia-smi présent mais aucun GPU lu"; fi
else
  warn "Pas de nvidia-smi : Ollama tournera sur CPU (plus lent, fonctionnel)"
fi

# 8. Ollama (informatif jusqu'à la semaine 3)
if curl -fsS --max-time 3 "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
  ok "Ollama répond sur localhost:${OLLAMA_PORT}"
else
  warn "Ollama ne répond pas sur localhost:${OLLAMA_PORT} (normal avant la semaine 3, voir docs/WSL2.md)"
fi

# 9. Repo GitOps
if [[ -z "${REPO_URL:-}" ]]; then
  warn "REPO_URL vide : Argo CD sera installé sans application racine (voir profiles/local.env.example)"
fi

if (( errors > 0 )); then
  die "$errors vérification(s) bloquante(s)."
fi
ok "Machine prête pour le profil $PROFILE"
