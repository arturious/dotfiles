#!/usr/bin/env bash
# Prints " branch [!]" for the git repo at $1 (dirty flag if uncommitted
# changes), or nothing if $1 isn't inside a git work tree. Used by
# window-status-format/window-status-current-format in tmux.conf.
set -euo pipefail

dir="${1:-.}"

branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
  printf ' %s [!]' "$branch"
else
  printf ' %s' "$branch"
fi
