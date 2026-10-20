# Préparer un PC Windows (WSL2)

Machine de référence : i7-9750H, 16 Go de RAM, GTX 1650 (4 Go), Windows 64 bits.

## 1. Plafonner WSL2

Dans `C:\Users\<toi>\.wslconfig` :

```ini
[wsl2]
memory=10GB
processors=6
swap=4GB
```

Puis dans PowerShell : `wsl --shutdown`, et rouvre ton terminal Ubuntu.

## 2. Vérifier cgroup v2 (bloquant)

Les versions récentes du kubelet refusent de démarrer sur un hôte en cgroup v1, et un nœud kind hérite des cgroups de WSL2. Ce blocage a été constaté en testant ce repo sur une machine en cgroup v1.

1. Dans PowerShell : `wsl --update`, puis `wsl --version`.
2. Dans Ubuntu : `stat -fc %T /sys/fs/cgroup/` doit afficher `cgroup2fs`.
3. Si le résultat est `tmpfs`, ajoute dans la section `[wsl2]` du `.wslconfig` :

   ```ini
   kernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1
   ```

   puis `wsl --shutdown`.

D'après le dépôt communautaire [spurin/wsl-cgroupsv2](https://github.com/spurin/wsl-cgroupsv2), cgroup v2 est le mode par défaut à partir de WSL 2.5.1. Je n'ai pas recoupé cette information avec la documentation de Microsoft. `make preflight` effectue ce contrôle.

## 3. Activer systemd dans WSL

Dans `/etc/wsl.conf` (côté Ubuntu) :

```ini
[boot]
systemd=true
```

Puis `wsl --shutdown` dans PowerShell.

## 4. Docker Engine dans WSL2

Suis la [documentation officielle pour Ubuntu](https://docs.docker.com/engine/install/ubuntu/), puis ajoute ton utilisateur au groupe `docker` :

```bash
sudo usermod -aG docker "$USER"   # puis ferme et rouvre le terminal
docker run --rm hello-world
```

Docker Desktop fonctionne aussi. Vérifie avant que ses conditions de licence conviennent à ton usage, surtout sur un poste d'entreprise.

## 5. Outils

Installe kind, kubectl, make, git et curl selon leur documentation (liens dans le README). Clone le repo **dans le système de fichiers Linux** (`~/ai-platform-lab`), pas sous `/mnt/c` : c'est nettement plus rapide.

## 6. GPU et Ollama (semaine 3)

- Le GPU est fourni à WSL2 par le **pilote NVIDIA Windows**. N'installe pas de pilote NVIDIA dans Ubuntu. Vérifie avec `nvidia-smi` dans WSL.
- Installe Ollama dans WSL en suivant [docs.ollama.com](https://docs.ollama.com).
- Par défaut, Ollama n'écoute que sur `127.0.0.1:11434`. Le cluster kind ne peut donc pas le joindre. D'après la [FAQ Ollama](https://docs.ollama.com/faq), il faut ouvrir l'éditeur avec `sudo systemctl edit ollama.service` puis ajouter :

  ```ini
  [Service]
  Environment="OLLAMA_HOST=0.0.0.0:11434"
  ```

  puis `sudo systemctl daemon-reload && sudo systemctl restart ollama`.
- Ollama n'a pas d'authentification. En mode réseau NAT (défaut de WSL2), le port n'est pas exposé sur ton réseau local. Ne l'expose pas au-delà.
- Contrôle : `make llm-check`.

## 7. Disque

Le disque virtuel de WSL2 grossit sans se réduire seul. Nettoie chaque semaine avec `docker system prune`, et `make down` si tu n'utilises pas le cluster.
