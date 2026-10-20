# 0001. Périmètre : une plateforme Data/IA locale sur kind

- Statut : accepté
- Date : 2026-10-20

## Contexte

Objectif : monter en compétence sur les thèmes de KCD Provence 2026 (plateforme self-service, gateway LLM, GitOps, sécurité, observabilité) et le montrer dans un repo public.

Contraintes : un portable de 16 Go de RAM sous Windows avec un GPU de 4 Go, aucun compte cloud ni clé API, un MVP au 14 novembre 2026.

## Options étudiées

| Option | Pour | Contre |
|---|---|---|
| kind | Léger, multi-nœuds, standard en CI, jetable | Pas de GPU dans le cluster sans configuration avancée |
| k3d | Très léger | Distribution k3s, moins proche de Kubernetes « amont » |
| minikube | Nombreux addons | Plus lourd, addons qui masquent ce qu'on veut apprendre |
| Cluster managé | Proche de la production | Coût, compte cloud, secret à gérer dès le début |

## Décision

kind, avec une configuration par profil de machine. Le LLM tourne hors du cluster (ADR 0003).

## Conséquences

- La CI GitHub Actions peut démarrer exactement la même plateforme.
- Hors périmètre : KAITO (vise des nœuds GPU provisionnés) et Falco (dépend du noyau, fragile sous WSL2).
- Les couches s'activent une à une sur le profil `laptop` pour tenir dans 10 Go.

## Coût de sortie

Faible pour les ressources dans `gitops/`, qui sont du Kubernetes standard. À réécrire : `cluster/` et la partie création de cluster de `scripts/up.sh`, soit environ une demi-journée pour passer à k3d ou à un cluster managé.
