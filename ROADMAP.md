# Roadmap

Objectif : un MVP démontrable le 14 novembre 2026, puis une version finalisée pour KCD Provence le 10 décembre 2026.

Règle pour chaque étape : une PR, un test vérifiable (CI ou commande `make`), un ADR si une décision est prise.

Légende : `[x]` fourni dans le squelette, à exécuter sur ta machine pour valider ; `[ ]` à faire.

## Semaine 1 (20-26 oct.) : socle GitOps

- [x] Cluster kind scripté, deux profils (`laptop`, `workstation`)
- [x] Installation d'Argo CD et application racine
- [x] Service `ollama` vers un backend hors cluster
- [x] CI : validation statique, puis démarrage complet sur runner GitHub
- [x] ADR 0001 à 0004
- [ ] Préparer WSL2 (docs/WSL2.md) et lancer `make up` sur le portable
- [ ] Pousser sur GitHub, renseigner `REPO_URL`, voir l'application `root` en état Synced
- [ ] Mesurer la RAM réelle (`make status`) et ajuster les seuils de `profiles/laptop.env`

Session liée : Katia Himeur (réversibilité).

## Semaine 2 (27 oct.-2 nov.) : self-service

- [ ] Schéma JSON du descripteur `service.yaml`
- [ ] Chart Helm générique (Deployment, Service, HTTPRoute)
- [ ] ApplicationSet : une application par équipe déclarée dans Git
- [ ] ResourceQuota, LimitRange et NetworkPolicy par équipe
- [ ] Kyverno : interdire `latest`, exiger les limites, restreindre les registries

Sessions liées : Doctolib (plateforme self-service), Aurélie Vache (Kyverno).

## Semaine 3 (3-9 nov.) : gateway LLM

- [ ] Ollama installé et exposé (docs/WSL2.md), `make llm-check` au vert
- [ ] Choix du modèle (1 à 3 milliards de paramètres sur le profil laptop), ajout à l'ADR 0003
- [ ] Envoy Gateway et Gateway API pour l'exposition
- [ ] agentgateway devant Ollama : API compatible OpenAI
- [ ] Budget de tokens par équipe
- [ ] Bascule entre deux backends (second modèle ou faux serveur compatible OpenAI)
- [ ] Décision de l'ADR 0004 (secrets)

Sessions liées : France Travail (agentgateway), Giant Swarm et NumSpot (Gateway API).

## Semaine 4 (10-14 nov.) : observabilité et supply chain, MVP

- [ ] OpenTelemetry Collector, métriques de tokens par équipe
- [ ] Stack Grafana légère, tableau de bord par équipe
- [ ] Sampling et filtrage pour maîtriser le volume
- [ ] Trivy Operator (concurrence limitée) et Policy Reporter
- [ ] Figer les versions (Argo CD et charts)
- [ ] **MVP** : démo de bout en bout enregistrée (asciinema ou vidéo)

Sessions liées : Kasper Nissen, Adriana Villela et Josh Lee (observabilité), Paul-Alexandre Chrétien (sécurité).

## Semaine 5 (15-21 nov.) : data

- [ ] Type `data-job` dans le descripteur
- [ ] MinIO et un job d'ingestion vers Parquet
- [ ] Job d'évaluation du LLM sur un jeu de questions synthétique

## Semaine 6 (22-28 nov.) : sécurité du chemin Git

- [ ] CODEOWNERS et protection de branche
- [ ] Policies Kyverno contre l'élévation de privilèges via des manifestes
- [ ] Policies Kyverno en mode audit pour détecter des comportements à risque
- [ ] Test de charge k6 sur la gateway

Sessions liées : Cédric Moulard (Git comme chemin d'écriture), Thibaud Vaisseau (benchmark de gateway).

## Semaine 7 (29 nov.-5 déc.) : capitalisation

- [ ] Schémas d'architecture à jour
- [ ] README orienté démo
- [ ] Article de blog ou post

## Semaine 8 (6-9 déc.) : préparation de KCD Provence

- [ ] Agenda de la journée
- [ ] Questions par session, tirées de ce qui a été construit

## Options

- Overlay `backend-claude` si une clé API devient disponible (voir ADR 0003)
- Crossplane ou kro à la place du chart Helm
- Sveltos (session event-driven)
