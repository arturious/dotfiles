#!/usr/bin/env bash
# Prints " #[fg=#859901]branch #[fg=#DC302E][!]" for the git repo at $1 (dirty
# flag if uncommitted changes), or nothing if $1 isn't inside a git work tree.
# The #[fg=...] tags are tmux style tags - tmux parses them in the final
# rendered status-line text regardless of whether they came from literal
# tmux.conf text or from this script's stdout via #(). Used by
# window-status-format/window-status-current-format in tmux.conf.
set -euo pipefail

dir="${1:-.}"

branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
  printf ' #[fg=#859901]%s #[fg=#DC302E][!]' "$branch"
else
  printf ' #[fg=#859901]%s' "$branch"
fi
