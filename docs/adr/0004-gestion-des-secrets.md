# 0004. Gestion des secrets en GitOps

- Statut : proposé (décision en semaine 3)
- Date : 2026-10-20

## Contexte

Argo CD déploie ce qui est dans Git, et le repo est public. Plusieurs couches auront besoin de secrets : mots de passe de Grafana et MinIO, et une clé API si l'overlay `backend-claude` est activé.

## Options étudiées

| Option | Pour | Contre |
|---|---|---|
| Sealed Secrets | Secret chiffré commité, simple | Clé liée au cluster : à sauvegarder, car kind est jetable |
| SOPS + age | Chiffrement par fichier, indépendant du cluster | Plugin Argo CD ou déchiffrement à l'installation |
| External Secrets Operator + backend local | Modèle proche de la production | Un composant de plus à faire tourner sur 10 Go |
| Secrets créés par `scripts/up.sh` depuis `local.env` | Aucun composant | Hors GitOps, non audité |

## Décision

À prendre en semaine 3. Critère principal : recréer le cluster (`make down && make up`) sans perdre l'accès aux secrets.

## Coût de sortie

À évaluer pour l'option retenue.
