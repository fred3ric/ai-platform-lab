# Faire tourner la plateforme sur une autre machine

## Principe

Tout ce qui décrit la plateforme est dans Git. Tout ce qui dépend de la machine est dans le profil et dans `profiles/local.env` (ignoré par Git).

| Dans Git (identique partout) | Propre à la machine |
|---|---|
| `gitops/` : ce qu'Argo CD déploie | `profiles/local.env` : `REPO_URL`, `OLLAMA_ADDR`, `OLLAMA_MODEL` |
| `cluster/` : topologie par profil | Le Service `ollama` (adresse IP), créé par `make up` |
| `scripts/`, `Makefile` | Ollama et les modèles téléchargés |

Un cluster kind est jetable : on ne le déplace pas, on le recrée avec `make up` sur la nouvelle machine.

## Passer sur une machine plus puissante

```bash
git clone https://github.com/<votre-compte>/ai-platform-lab.git ~/ai-platform-lab
cd ~/ai-platform-lab
cp profiles/local.env.example profiles/local.env   # REPO_URL, éventuellement OLLAMA_MODEL
make preflight PROFILE=workstation
make up PROFILE=workstation
```

Ajuste `MIN_RAM_MB` et `MIN_DISK_GB` dans `profiles/workstation.env` à la machine réelle. Les valeurs actuelles sont des hypothèses.

## Ce qui change d'un profil à l'autre

| | `laptop` | `workstation` |
|---|---|---|
| Nœuds kind | 1 | 3 (1 plan de contrôle, 2 workers) |
| Quota de `team-demo` | 2 CPU, 2 Gi demandés | 8 CPU, 16 Gi demandés |
| Couches simultanées | une à la fois | toutes |
| Modèle LLM | 1 à 3 milliards de paramètres | plus gros selon la VRAM |

Pour ajouter une couche à un seul profil, ajoute-la dans `gitops/profiles/<profil>/kustomization.yaml`. Pour l'ajouter partout, mets-la dans `gitops/base/`.

## Ajouter un profil

1. Copier `profiles/workstation.env` vers `profiles/<nom>.env` et l'adapter.
2. Créer `cluster/kind-<nom>.yaml`.
3. Créer `gitops/profiles/<nom>/` avec son `kustomization.yaml`.
4. `make validate`, puis `make up PROFILE=<nom>`.

## Où tourne le modèle

| Situation | `OLLAMA_ADDR` |
|---|---|
| Ollama sur la même machine, Docker sous Linux ou WSL2 | vide (détection automatique : passerelle du réseau Docker `kind`) |
| Ollama sur une autre machine du réseau (station avec un meilleur GPU) | adresse IP de cette machine |
| macOS avec Docker Desktop (non testé) | `host.docker.internal` |

Le portable peut ainsi utiliser le GPU de la station : `OLLAMA_ADDR=<ip-de-la-station>` dans `profiles/local.env`, puis `make up`. Ollama n'a pas d'authentification : limite cet usage à un réseau de confiance.

## Preuve de portabilité

Le job `e2e` de la CI démarre la plateforme (profil `laptop`) sur un runner GitHub vierge à chaque push sur `main`. S'il passe, le repo est autonome.
