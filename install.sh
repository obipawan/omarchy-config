#!/usr/bin/env bash
#
# install.sh — (re)build a fresh Omarchy install from this repo.
#
# Idempotent: safe to run repeatedly. Every overwritten file is backed up to
# <target>.bak.<epoch> first. Nothing in /usr/share/omarchy/ is touched.
#
# Usage:
#   ./install.sh                      # copy configs, install plugins/theme
#   OPENROUTER_MANAGEMENT_KEY=sk-or-REPLACE_ME ./install.sh   # also write agent key
#   ./install.sh --dry-run            # show what would happen, change nothing
#
# Manual prerequisites on a brand-new machine:
#   1. Install Omarchy and log in once so ~/.config/hypr and
#      ~/.config/omarchy exist (first-boot generates stock defaults we back up).
#   2. Have an internet connection so `omarchy plugin add` can clone remotes.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
OM="$CFG/omarchy"
DRY="${OMARCHY_INSTALL_DRY:-$([ "${1:-}" = "--dry-run" ] && echo 1 || echo 0)}"

# Repos referenced by shell.json whose plugins ship remotely (installed via the
# idiomatic `omarchy plugin add`). Nickname|github-url
GIT_PLUGINS=(
  "obi.stats|https://github.com/obipawan/omarchy-stats"
  "digitalbase.openrouter-plus-improved|https://github.com/digitalbase/omarchy-openrouter-plus-improved"
)

info()  { printf '\033[1;36m[omarchy-config]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[omarchy-config]\033[0m %s\n' "$*"; }
saydry() { [[ "$DRY" == 1 ]] && printf '\033[1;33m[dry-run]\033[0m %s\n' "$*" || true; }

backup() { # backup <path> — copy an existing file to <path>.bak.<epoch>
  local p="$1" bak
  [[ -e "$p" ]] || return 0
  [[ "$DRY" == 1 ]] && { saydry "would back up $p"; return 0; }
  bak="${p}.bak.$(date +%s)"
  cp -a "$p" "$bak"
  info "backed up $p -> $bak"
}

copy_file() { # copy_file <src> <dst>
  local src="$1" dst="$2"
  [[ -f "$src" ]] || { warn "missing $src — skipping"; return 0; }
  backup "$dst"
  if [[ "$DRY" == 1 ]]; then saydry "copy $src -> $dst"; return 0; fi
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  info "wrote $dst"
}

copy_tree() { # copy_tree <src> <dst> — merges a directory (overwrites files)
  local src="$1" dst="$2"
  [[ -d "$src" ]] || { warn "missing $src — skipping"; return 0; }
  backup "$dst"
  if [[ "$DRY" == 1 ]]; then saydry "copy tree $src -> $dst"; return 0; fi
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
  info "merged $src -> $dst"
}

run_cmd() { # run_cmd <desc> <cmd...> — run an omarchy command (honours dry-run)
  if [[ "$DRY" == 1 ]]; then saydry "run: $*"; return 0; fi
  info "run: $*"
  "$@"
}

[[ "$DRY" == 1 ]] && warn "DRY-RUN — no changes will be made"
info "Repo: $REPO_DIR"

## 1. Hyprland user config (window rules, input, keybindings) ----------------
copy_file "$REPO_DIR/hypr/input.lua"    "$CFG/hypr/input.lua"
copy_file "$REPO_DIR/hypr/bindings.lua" "$CFG/hypr/bindings.lua"

## 2. Omarchy shell (bar layout + idle) and custom bar module ----------------
copy_file "$REPO_DIR/omarchy/shell.json" "$OM/shell.json"
copy_file "$REPO_DIR/omarchy/shell.toml" "$OM/shell.toml"          # bar font size
copy_file "$REPO_DIR/omarchy/defaults/agent" "$OM/defaults/agent"  # default agent
copy_file "$REPO_DIR/omarchy/bar/modules/chevron-left.qml" "$OM/bar/modules/chevron-left.qml"

## 3. Custom theme "minimal" --------------------------------------------------
copy_tree "$REPO_DIR/themes/minimal" "$OM/themes/minimal"
run_cmd omarchy theme set minimal

## 4. Local fork plugins (pawan.clock, pawan.workspaces) ---------------------
copy_tree "$REPO_DIR/plugins/pawan.clock"       "$OM/plugins/pawan.clock"
copy_tree "$REPO_DIR/plugins/pawan.workspaces"  "$OM/plugins/pawan.workspaces"
for p in pawan.clock pawan.workspaces; do
  chmod -R u+w "$OM/plugins/$p"
  run_cmd omarchy plugin validate "$OM/plugins/$p" >/dev/null 2>&1 \
    && info "validated plugin $p" || warn "plugin validate $p returned non-zero"
done

## 5. Git-managed plugins (obi.stats, openrouter-plus-improved) --------------
for entry in "${GIT_PLUGINS[@]}"; do
  id="${entry%%|*}"; url="${entry##*|}"
  if [[ "$DRY" == 1 ]]; then
    saydry "omarchy plugin add $url   # -> $id"
    continue
  fi
  if [[ -d "$OM/plugins/$id" ]]; then
    info "plugin $id already present — skipping add (update with: omarchy plugin update $id)"
  else
    info "adding plugin $id from $url"
    yes n | omarchy plugin add "$url" --yes >/dev/null 2>&1 \
      || warn "could not 'plugin add' $id (offline? already added?) — install manually later"
  fi
done

## 6. OpenRouter agent key (secret) ------------------------------------------
AGENT_FILE="$OM/agents/openrouter.json"
if [[ "$DRY" != 1 && -n "${OPENROUTER_MANAGEMENT_KEY:-}" ]]; then
  backup "$AGENT_FILE"
  mkdir -p "$OM/agents"
  sed "s|__OPENROUTER_MANAGEMENT_KEY__|$OPENROUTER_MANAGEMENT_KEY|" \
    "$REPO_DIR/omarchy/agents/openrouter.json.tpl" > "$AGENT_FILE"
  info "wrote $AGENT_FILE (key supplied via env)"
elif [[ "$DRY" != 1 && -f "$AGENT_FILE" ]]; then
  warn "agent key file already exists — leaving it (key not in repo)"
else
  warn "no OPENROUTER_MANAGEMENT_KEY set — skipping OpenRouter agent config"
fi

## 7. Misc user configs (optional) --------------------------------------------
copy_file "$REPO_DIR/misc/starship.toml" "$CFG/starship.toml"
# git identity is intentionally NOT written automatically; see misc/gitconfig.

## 8. Apply / reload ----------------------------------------------------------
if [[ "$DRY" == 1 ]]; then
  saydry "apply: hyprctl reload; hyprctl configerrors; omarchy restart shell"
  exit 0
fi
info "validating + reloading..."
hyprctl reload >/dev/null 2>&1 || warn "hyprctl reload failed"
hyprctl configerrors || true
omarchy restart shell >/dev/null 2>&1 || warn "omarchy restart shell failed"
info "DONE. Review bar with 'omarchy plugin list' and remount any agent in the settings panel."