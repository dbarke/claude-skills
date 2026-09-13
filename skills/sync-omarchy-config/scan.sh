#!/bin/bash

# Read-only report for the sync-omarchy-config skill. Changes nothing.

GIT_DIR="${OMARCHY_CONFIG_GIT_DIR:-$HOME/.omarchy-config.git}"
OMARCHY_DEFAULTS="${OMARCHY_PATH:-/usr/share/omarchy}/config"
cfg() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

[[ -d $GIT_DIR ]] || { echo "No repo at $GIT_DIR (see First run in SKILL.md)"; exit 1; }
cd "$HOME" || exit 1

section() { printf '\n## %s\n' "$1"; }

section "Remote"
cfg fetch -q origin 2>&1 || echo "(fetch failed)"
cfg status -sb | head -1

section "Tracked files: changed or deleted"
cfg status --short | grep . || echo "(none)"

tracked=$(cfg ls-files)
is_tracked() { grep -qxF "$1" <<<"$tracked"; }
mapfile -t ignored < <(sed -E 's/#.*//; s/[[:space:]]+$//; /^$/d' .config/omarchy-config/ignore.txt 2>/dev/null)
# Omarchy-owned, noisy, or deliberately ignored files that are never worth suggesting.
skip() {
  [[ $1 =~ \.bak(\.|-)|\.log$|\.sock|\.pid$|\.lock$|session\.json|release-notes\.json|/\.luarc\.json$ ]] && return 0
  local pat
  for pat in "${ignored[@]}"; do
    # shellcheck disable=SC2053
    [[ $1 == $pat ]] && return 0
  done
  # Omarchy installs these generated files itself.
  [[ $1 == .config/omarchy/hooks/* ]] && cmp -s "$1" "${OMARCHY_PATH:-/usr/share/omarchy}/install/user/first-run/$(basename "$1")" && return 0
  grep -qs '^# Written by omarchy-install' "$1" && return 0
  return 1
}

section "Untracked: Omarchy config you changed from the defaults"
for dir in "$OMARCHY_DEFAULTS"/*; do
  name=$(basename "$dir")
  [[ $name == chromium ]] && continue
  if [[ -d $dir ]]; then
    find "$dir" -type f 2>/dev/null | while read -r def; do
      rel=".config/${def#"$OMARCHY_DEFAULTS"/}"
      [[ -f $rel ]] && ! is_tracked "$rel" && ! skip "$rel" && ! cmp -s "$def" "$rel" && echo "$rel"
    done
  else
    rel=".config/$name"
    [[ -f $rel ]] && ! is_tracked "$rel" && ! cmp -s "$dir" "$rel" && echo "$rel"
  fi
done

section "Untracked: user files in Omarchy/Hyprland dirs"
find .config/hypr .config/omarchy/{extensions,hooks,themes,themed,branding,defaults} \
  .local/state/omarchy/{workspace-layouts,settings} \
  -type f -not -name '*.sample' 2>/dev/null | while read -r f; do
  is_tracked "$f" || skip "$f" || echo "$f"
done
find .local/state/omarchy/toggles -type f -not -name flags.lua 2>/dev/null | while read -r f; do
  is_tracked "$f" || echo "$f  (active toggle)"
done

section "Untracked: personal scripts and user units"
find .local/bin -maxdepth 1 -type f 2>/dev/null | while read -r f; do
  # Skip tool shims (mise/omarchy installers generate these).
  is_tracked "$f" || skip "$f" || { head -c 200 "$f" | grep -q 'mise\|exec .*shims' && continue; echo "$f"; }
done
find .config/systemd/user -maxdepth 1 -type f 2>/dev/null | while read -r f; do
  is_tracked "$f" || skip "$f" || echo "$f"
done

section "Untracked: other configs edited since the last commit"
since=$(cfg log -1 --format=%cI 2>/dev/null)
find .config -maxdepth 3 -type f -newermt "$since" \
  -not -path '.config/omarchy/plugins/*' 2>/dev/null |
  grep -vE '^\.config/(BraveSoftware|chromium|google-chrome|microsoft-edge|spotify|dconf|pulse|gh|ibus|fcitx|fcitx5|nextjs-nodejs|obsidian|Code|systemd/user/[^/]+\.wants)' |
  while read -r f; do is_tracked "$f" || skip "$f" || echo "$f"; done

section "Shell plugins: installed vs plugins.txt"
listed=$(grep -vE '^\s*(#|$)' .config/omarchy-config/plugins.txt 2>/dev/null | awk '{print $1}' | sort)
installed=$(for p in .config/omarchy/plugins/*/; do basename "$p"; done | sort)
comm -13 <(echo "$listed") <(echo "$installed") | while read -r id; do
  [[ -n $id ]] && echo "missing from plugins.txt: $id $(git -C ".config/omarchy/plugins/$id" remote get-url origin 2>/dev/null || echo '(no git remote)')"
done
comm -23 <(echo "$listed") <(echo "$installed") | while read -r id; do
  [[ -n $id ]] && echo "listed but not installed: $id"
done

section "Look (restore.sh hardcodes these)"
echo "theme: $(omarchy theme current 2>/dev/null)"
echo "font:  $(omarchy font current 2>/dev/null)"
grep -E 'omarchy (theme|font) set' .config/omarchy-config/restore.sh

section "Enabled user units"
systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null | awk '{print $1}' |
  while read -r u; do [[ -f .config/systemd/user/$u ]] && echo "$u"; done
