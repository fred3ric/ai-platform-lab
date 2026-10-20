# Consignes pour Claude Code

Projet d'apprentissage en platform engineering. Son auteur veut comprendre chaque brique : explique tes choix et préfère une solution simple qu'il peut relire.

## Contexte

- Plateforme locale sur kind, synchronisée par Argo CD depuis ce repo.
- Deux profils : `laptop` (16 Go de RAM, WSL2 plafonné à 10 Go, GPU 4 Go) et `workstation`. Tout changement doit fonctionner sur `laptop`.
- Le LLM (Ollama) tourne hors du cluster. Le Service `ollama` du namespace `llm-backends` est créé par `scripts/up.sh`, car il dépend de la machine.
- Roadmap : `ROADMAP.md`. Décisions : `docs/adr/`.

## Méthode

1. Avant de coder, reformule l'intention et propose un plan court. Attends sa validation.
2. Toute décision d'architecture donne un ADR (`docs/adr/0000-template.md`), avec la section « Coût de sortie ».
3. Une étape de la roadmap correspond à une PR et à un test vérifiable.
4. Termine chaque étape avec `make validate` au vert. Si un cluster tourne, termine avec `make status`.

## Règles

- Rien de propre à la machine dans `gitops/` : adresses IP, chemins, secrets vont dans `profiles/local.env` ou sont créés par les scripts.
- Aucun secret dans Git. Aucune donnée réelle (client, Ippon) : données synthétiques uniquement.
- Fige les versions des images et des charts. Vérifie les versions et les options dans la documentation officielle au lieu de les écrire de mémoire.
- Scripts compatibles bash 3.2 (macOS) : pas de `mapfile` ni de `${var,,}`.
- Pour chaque nouvelle couche, indique son coût en RAM. Rends-la activable séparément sur le profil `laptop`.

## Commandes

```bash
make validate                 # sans cluster
make up PROFILE=laptop        # idempotent
make status
make llm-check
```
