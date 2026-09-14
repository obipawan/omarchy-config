# Plugins in this folder are the two local forks (pawan.clock, pawan.workspaces)
# — hand-edited copies of stock plugins, installed by copying the directory.
#
# The other two plugins referenced by omarchy/shell.json are git-managed and
# reinstalled by install.sh via the idiomatic `omarchy plugin add`:
#
#   obi.stats
#     install:  omarchy plugin add https://github.com/obipawan/omarchy-stats
#     notes:    see https://github.com/obipawan/omarchy-stats (AGENTS.md documents
#               the develop-live -> back-source workflow). Repo lives at
#               ~/Work/omarchy-stats on this machine.
#
#   digitalbase.openrouter-plus-improved
#     install:  omarchy plugin add https://github.com/digitalbase/omarchy-openrouter-plus-improved
#     requires: OpenRouter management key -> ~/.config/omarchy/agents/openrouter.json