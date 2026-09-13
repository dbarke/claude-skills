#!/bin/bash

# Symlink every skill in this repo into ~/.claude/skills, so edits here are live
# and `git pull` updates them. Pass skill names to install only those.
#
#   ./install.sh                 # all skills
#   ./install.sh handoff pickup  # just these

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$TARGET_DIR"

if (($#)); then
  skills=("$@")
else
  skills=()
  for dir in "$REPO_DIR"/skills/*/; do skills+=("$(basename "$dir")"); done
fi

for name in "${skills[@]}"; do
  src="$REPO_DIR/skills/$name"
  dest="$TARGET_DIR/$name"

  [[ -f $src/SKILL.md ]] || { echo "skip $name: no skills/$name/SKILL.md"; continue; }

  if [[ -L $dest && $(readlink -f "$dest") == "$src" ]]; then
    echo "ok   $name (already linked)"
  elif [[ -e $dest || -L $dest ]]; then
    echo "skip $name: $dest exists; move it away and re-run"
  else
    ln -s "$src" "$dest"
    echo "link $name -> $dest"
  fi
done
