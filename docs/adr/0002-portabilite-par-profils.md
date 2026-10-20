# 0002. Portabilité : profils de machine et séparation Git / machine

- Statut : accepté
- Date : 2026-10-20

## Contexte

La plateforme doit tourner sur le portable (16 Go) et sur une machine plus puissante, sans dupliquer le code ni modifier Git à chaque changement de machine.

## Options étudiées

| Option | Pour | Contre |
|---|---|---|
| Une branche par machine | Simple au départ | Divergence, fusions pénibles |
| Profils : variables, config kind et dossier Kustomize par profil | Un seul code, différences explicites | Un peu de structure à maintenir |
| Tout paramétrer par Helm values | Souple | Masque la structure Kubernetes qu'on veut apprendre |

## Décision

Un profil se compose de trois éléments portant le même nom : `profiles/<profil>.env`, `cluster/kind-<profil>.yaml` et `gitops/profiles/<profil>/`. Les ressources communes vont dans `gitops/base/`. Ce qui dépend de la machine (adresse d'Ollama, URL du repo) va dans `profiles/local.env`, ignoré par Git, ou est créé par `scripts/up.sh`.

## Conséquences

- Changer de machine revient à `git clone` puis `make up PROFILE=<profil>`.
- Le job `e2e` de la CI vérifie la portabilité sur une machine vierge.
- Toute ressource ajoutée doit être classée : commune, propre à un profil ou propre à la machine.

## Coût de sortie

Faible : les profils sont des overlays Kustomize standard, réutilisables tels quels avec Flux ou un simple `kubectl apply -k`.
