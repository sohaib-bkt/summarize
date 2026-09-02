#!/usr/bin/env bash
#
# install.sh — Installe le skill "summarize" + le skill "agent-reach"
# dans les répertoires de skills d'un agent (opencode / claude code / autres).
#
# Le skill est agnostique : il s'adapte aux outils natifs de n'importe quel
# agent harness. Ce script ne fait que copier les skills dans le bon dossier
# et vérifier les dépendances de fetch (yt-dlp / curl).
#
# Usage:
#   ./install.sh                    # installe vers ~/.agents/skills (défaut)
#   ./install.sh --dir=DIR          # installe vers un répertoire précis
#   ./install.sh --help

set -euo pipefail

# ---------------------------------------------------------------------------
# Chemins
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"   # ex: ~/dev/summarize
SOURCE_SKILLS="$REPO_ROOT/skills"

# Cible par défaut : répertoire de skills courant de l'agent
DEFAULT_TARGET="${HOME}/.agents/skills"
TARGET_DIR="${DEFAULT_TARGET}"

usage() {
  cat <<EOF
Usage: $0 [options]

Installe les skills "summarize" et "agent-reach" depuis ce dépôt vers un
répertoire de skills d'un agent, puis vérifie les dépendances de fetch.

Répertoires de skills courants par agent :
  opencode / agents divers : ~/.agents/skills
  Claude Code              : ~/.claude/skills
  Cursor                   : ~/.cursor/skills
  npx/@modelcontextprotocol : variable du dossier courant

Options:
  --dir=DIR        Répertoire d'installation des skills
                   (défaut: ~/.agents/skills)
  -h, --help       Affiche cette aide

Exemples:
  ./install.sh                              # → ~/.agents/skills
  ./install.sh --dir=~/.claude/skills       # → pour Claude Code
  ./install.sh --dir=~/.cursor/skills       # → pour Cursor
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir=*) TARGET_DIR="${1#*=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Option inconnue: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# ---------------------------------------------------------------------------
# 1. Vérifier / créer le répertoire cible
# ---------------------------------------------------------------------------
echo "→ Répertoire cible des skills : $TARGET_DIR"
mkdir -p "$TARGET_DIR"

# ---------------------------------------------------------------------------
# 2. Copier les skills
# ---------------------------------------------------------------------------
copy_skill() {
  local src="$1"
  local name
  name="$(basename "$src")"
  echo "→ Installation du skill : $name"
  rm -rf "$TARGET_DIR/$name"
  cp -R "$src" "$TARGET_DIR/$name"
  echo "   ✓ installé dans $TARGET_DIR/$name"
}

for d in "$SOURCE_SKILLS"/*; do
  [ -d "$d" ] && copy_skill "$d"
done

# ---------------------------------------------------------------------------
# 3. Vérifier / installer les dépendances
# ---------------------------------------------------------------------------
echo
echo "→ Vérification des dépendances..." 

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "   ✓ $1"
  else
    echo "   ✗ $1 (absent)"
    MISSING=1
  fi
}

MISSING=0
# Dépendances agent-reach
check_cmd yt-dlp        # YouTube (sous-titres)
check_cmd mcporter      # Exa search (facultatif)
check_cmd gh            # GitHub (facultatif)
# Dépendances summarize
check_cmd curl          # Jina reader / web

if [ "$MISSING" = "1" ]; then
  echo
  echo "⚠  Certaines dépendances sont absentes. Installez-les avec :"
  echo "   - yt-dlp :  pip install yt-dlp   ou   pipx install yt-dlp"
  echo "   - mcporter: npm i -g mcporter"
  echo "   - gh :      https://cli.github.com"
  echo
  echo "   yt-dlp est la dépendance principale pour résumer les vidéos YouTube."
fi

# ---------------------------------------------------------------------------
# 4. Dossier des résumés
# ---------------------------------------------------------------------------
mkdir -p "$HOME/summaries"
echo
echo "→ Dossier de sortie des résumés : $HOME/summaries"

echo
echo "✔ Installation terminée."
echo "  Redémarrez votre agent (opencode / claude code / etc.) pour recharger les skills."
echo "  Ensuite demandez simplement : \"résume cette vidéo <url>\" dans n'importe quel agent."
