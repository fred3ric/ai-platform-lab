# 0003. Backend LLM : Ollama hors du cluster, Claude en option

- Statut : accepté (choix du modèle à compléter en semaine 3)
- Date : 2026-10-20

## Contexte

La gateway LLM a besoin d'au moins un backend. Aucune clé API n'est disponible : le budget Claude de l'auteur passe par un abonnement entreprise (claude.ai et Claude Code), pas par la Console API. Le portable a un GPU de 4 Go.

## Options étudiées

| Option | Pour | Contre |
|---|---|---|
| Ollama sur l'hôte, joint par un Service sans sélecteur | Utilise le GPU sans configuration GPU dans kind ; adresse modifiable par machine | Dépendance hors cluster |
| Ollama dans le cluster, sur CPU | Tout dans Kubernetes | Lent, consomme la RAM du cluster |
| GPU passé à kind | Proche d'un cluster GPU réel | Configuration complexe, fragile sous WSL2 |
| API Claude via agentgateway | Modèles puissants, provider supporté par agentgateway | Clé API requise, coût, données envoyées hors de la machine |

## Décision

Ollama tourne sur l'hôte (ou sur une autre machine du réseau). Le cluster le joint via le Service `ollama.llm-backends`, créé par `scripts/up.sh` avec un EndpointSlice (adresse IP) ou un ExternalName (nom DNS). La bascule entre backends est testée entre deux backends locaux.

Claude devient une option : un overlay `backend-claude` (AgentgatewayBackend et Secret), activable si une clé API est obtenue.

Modèle : 1 à 3 milliards de paramètres, quantifié, pour le profil `laptop`. Choix précis en semaine 3.

## Conséquences

- Aucun coût ni aucune donnée qui sort de la machine.
- Sur la station, le portable peut utiliser le GPU distant (`OLLAMA_ADDR`).
- Ollama n'a pas d'authentification : il ne doit être joignable que depuis le réseau local ou la VM WSL2.

## Coût de sortie

Faible : la gateway expose une API compatible OpenAI, donc les équipes n'appellent jamais Ollama directement. Changer de backend revient à modifier la configuration de la gateway.
