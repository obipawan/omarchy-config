# omarchy-config

A self-documenting, reinstall-able backup of my Omarchy (Arch + Hyprland)
customizations. On a fresh machine: clone this repo, then `./install.sh`.

It should never touch `/usr/share/omarchy/` — everything it writes lives under
`~/.config/`, so it survives Omarchy updates and a reinstall.

## Contents

| Path in repo | Installed to | What it is |
|---|---|---|
| `hypr/input.lua` | `~/.config/hypr/` | keyboard layouts (`us,dk,eu` / `intl`), natural scroll, touchpad tuning (customized `o.input`) |
| `hypr/bindings.lua` | `~/.config/hypr/` | F-key media bindings: F1/F2 display brightness, F5/F6 keyboard brightness, F10–F12 volume (defaults unbound) |
| `omarchy/shell.json` | `~/.config/omarchy/` | bar layout (plugins/order/`chevron-left` group, center anchor) + idle lock 300s / screensaver 150s |
| `omarchy/shell.toml` | `~/.config/omarchy/` | bar font `base-size = 14` |
| `omarchy/defaults/agent` | `~/.config/omarchy/defaults/` | default agent = `hermes` |
| `omarchy/bar/modules/chevron-left.qml` | `~/.config/omarchy/bar/modules/` | custom chevron widget that collapses/hides bluetooth+monitor+power with an animated toggle |
| `themes/minimal/` | `~/.config/omarchy/themes/` | my custom "minimal" theme (colors, hyprland borders, btop, icons, neovim, vscode, backgrounds) |
| `plugins/pawan.clock/` | `~/.config/omarchy/plugins/` | fork of `omarchy.clock` (date/time + calendar popup, custom format `ddd d MMM h:mm`) |
| `plugins/pawan.workspaces/` | `~/.config/omarchy/plugins/` | fork of `omarchy.workspaces` (workspace indicators) |
| `misc/starship.toml` | `~/.config/starship.toml` | minimal starship prompt |
| `misc/gitconfig` | reference only | my git aliases + identity (NOT auto-installed) |
| `omarchy/agents/openrouter.json.tpl` | → `openrouter.json` | OpenRouter agent key **template** — key is injected from env, never committed |

## Not included (regenerated / not mine)

- `hypr/autostart.lua`, `looknfeel.lua` — stock (only comments changed).
- `hypr/hyprland.lua`, `monitors.lua` — no user overrides.
- `misc/*.bak`, theme `*.bak.*` — transient backups.
- Terminal configs (alacritty/kitty/foot/ghostty) and `btop.conf` — regenerated
  from the theme's `colors.toml`, no manual edits.
- Hooks under `~/.config/omarchy/hooks/` (`setup-agent`, `setup-fingerprint`,
  `install-voxtype`, etc.) — stock Omarchy first-run onboarding; a fresh
  install recreates them.

## Reinstalling fresh

```bash
git clone <this-repo-url> ~/omarchy-config && cd ~/omarchy-config
./install.sh --dry-run        # review
./install.sh                  # apply
```

What `install.sh` does, in order:

1. Sets `hypr/input.lua` + `hypr/bindings.lua` (backs up old copies first).
2. Puts `shell.json` + the `chevron-left` module in place.
3. Copies the `minimal` theme and applies it with `omarchy theme set minimal`.
4. Copies the `pawan.clock` and `pawan.workspaces` plugin dirs (validates each).
5. Installs the git-managed plugins the idiomatic way:
   `omarchy plugin add https://github.com/obipawan/omarchy-stats` (id `obi.stats`)
   `omarchy plugin add https://github.com/digitalbase/omarchy-openrouter-plus-improved`
6. Writes the OpenRouter agent key **only** if
   `OPENROUTER_MANAGEMENT_KEY=sk-or-REPLACE_ME` is set (never read from the repo).
7. Optionally copies `starship.toml`.
8. Reloads: `hyprctl reload`, `hyprctl configerrors`, `omarchy restart shell`.

## Keeping it current (one-way, repo ← live system)

The shell hot-reloads `~/.config/omarchy/`, so you edit the live copy and
test there first, then back-source into this repo and commit — the same
"develop live, back-source" convention obi.stats / omarchy-stats already uses:

```bash
# make a live change, verify it, then sync back and commit
cp ~/.config/hypr/input.lua hypr/
cp ~/.config/hypr/bindings.lua hypr/
cp ~/.config/omarchy/shell.json omarchy/
cp ~/.config/omarchy/plugins/pawan.clock/* plugins/pawan.clock/
git add -A && git commit -m "sync: ..."
```

## Security note

`~/.config/omarchy/agents/openrouter.json` holds a live management key. It is
git-ignored here. Always install with the key passed as an env var or entered
via an agent setup panel — never store it in this repo.