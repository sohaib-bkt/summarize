# Summarize — résumé détaillé de contenu web, pour agents (opencode)

Skill + outillage pour générer des **résumés détaillés** (rédaction narrative +
points clés) de vidéos YouTube, de posts Reddit, de pages web et de
conversations LLM partagées, puis les enregistrer dans `~/summaries/` sous
forme de fichiers Markdown.

Ce dépôt est **autonome** : il contient le skill `summarize` **et** le skill
`agent-reach` (avec toutes ses références), prêt à être cloné / poussé sur
GitHub et installé sur toute machine.

---

## Structure du dépôt

```
summarize/
├── README.md
├── .gitignore
├── skills/
│   ├── summarize/
│   │   └── SKILL.md              ← le skill summarize (agent-reach requis)
│   └── agent-reach/
│       ├── SKILL.md              ← le skill agent-reach (routeur 15 plateformes)
│       ├── SKILL_en.md
│       └── references/
│           ├── search.md
│           ├── social.md
│           ├── career.md
│           ├── dev.md
│           ├── web.md
│           ├── video.md
│           └── finance.md
└── scripts/
    ├── install.sh                ← installation automatique des skills
    └── summarize-cli             ← en ligne de mire : récupération du contenu brut
```

---

## Prérequis

Pour rendre **agent-reach** exactement comme sur la machine de développement,
réinstallez l'outil officiel (fourni par l'équipe agent-reach) :

```bash
# Agent Reach (outil + config) — source officielle
# https://github.com/Panniantong/agent-reach
pipx install agent-reach        # ou suivez install.md officiel
agent-reach doctor --json       # vérifie les channels disponibles
```

Dépendances principales (vérifiées par `install.sh`) :

| Outil | Rôle | Installation |
|-------|------|--------------|
| `yt-dlp` | Sous-titres YouTube | `pip install yt-dlp` ou `pipx install yt-dlp` |
| `curl` | Jina Reader (web/Reddit) | présent par défaut |
| `mcporter` | Exa search (facultatif) | `npm i -g mcporter` |
| `gh` | GitHub search (facultatif) | https://cli.github.com |

> `opencli` / `rdt` / `twitter` etc. (plateformes social/YouTube avancées)
> dépendent du backend agent-reach choisi. `install.sh` installe seulement le
> socle ; configurez les backends avec `agent-reach configure ...` si besoin.

---

## Installation

### Option A — Installation automatique

```bash
cd summarize
./scripts/install.sh                 # installe vers ~/.agents/skills
./scripts/install.sh --dir=DIR       # installe vers un répertoire précis
```

Ce script :
1. Copie `skills/summarize` et `skills/agent-reach` vers le dossier cible.
2. Vérifie les dépendances (`yt-dlp`, `curl`, …).
3. Installe `summarize-cli` dans `~/.local/bin` (option `--no-cli` pour omettre).
4. Crée le dossier de sortie `~/summaries`.

Puis redémarrez votre agent (opencode) pour recharger les skills.

### Option B — Copie manuelle

```bash
mkdir -p ~/.agents/skills
cp -R skills/* ~/.agents/skills/
# puis redémarrez opencode
```

### Vérification

Dans un agent opencode, tapez `/skills` — vous devriez voir `summarize`
et `agent-reach`. En CLI :

```bash
ls ~/.agents/skills/summarize ~/.agents/skills/agent-reach
```

---

## Utilisation

### Dans opencode (recommandé)

Après redémarrage, demandez simplement, dans votre langue :

```
résume cette vidéo https://youtu.be/XXXX
summarize https://www.youtube.com/watch?v=YYYY
résume ce post reddit https://www.reddit.com/...
explique cette page https://exemple.com/article
tl;dr https://chatgpt.com/share/...
```

Le skill `summarize` est déclenché automatiquement (phrases → `MUST USE`).
Il :
1. Détecte le type de contenu (YouTube / Reddit / web / conversation LLM).
2. Récupère la matière première via agent-reach (`yt-dlp`, Jina, `agent-reach`).
3. Rédige un **résumé détaillé** : essai narratif + points clés + citations.
4. Le sauvegarde dans `~/summaries/AAAA-MM-JJ-titre.md`.

### En CLI (filet de sécurité)

Quand aucun agent n'est disponible (ou pour prérécupérer le contenu) :

```bash
summarize <url>                 # affiche le contenu brut
summarize <url> -o /tmp/x.txt   # écrit le contenu brut dans un fichier
```

> La **rédaction du résumé** est faite par l'agent (modèle), pas par ce script.

### Format de sortie

Chaque résumé est un fichier Markdown dans `~/summaries/` avec un frontmatter :

```markdown
---
title: "Titre réel du contenu"
source: "https://url-originale"
type: "youtube|reddit|web|llm"
date: "2026-09-02"
duration: "43:39"        # vidéos uniquement
channel: "Chaîne"        # vidéos uniquement
---

# Titre

## Summary
(essai narratif détaillé en plusieurs paragraphes)

## Key Points
(points clés en puces)

## Notable Quotes
(citations importantes)

## Sources & References
```

---

## Personnalisation

- **Dossier de sortie** : remplacez `$HOME/summaries` par un autre chemin dans
  `SKILL.md` (section Étape 4) et dans `install.sh`.
- **Langue** : le skill rédige dans la langue de la source par défaut.
- **Phrases déclencheurs** : modifiez la `description:` du frontmatter de
  `skills/summarize/SKILL.md` pour ajouter vos propres formulations.

---

## Licence / Auteurs

- `summarize` : utilisation personnelle — voir l'auteur du dépôt.
- `agent-reach` : skill open-source de [Panniantong](https://github.com/Panniantong/agent-reach),
  redistribué ici sous sa licence d'origine pour une installation autonome.
