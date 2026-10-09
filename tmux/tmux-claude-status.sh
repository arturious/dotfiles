#!/usr/bin/env bash
# The state of the Claude Code running on a pane's tty: busy, idle, waiting
# or unknown - nothing when no Claude runs there. Status comes from the files
# Claude itself keeps in ~/.claude/sessions, read the same way
# tmux-claude-hatch does (scripts/agents.sh): same liveness check. Only the
# word: pane-border-format in settings.conf draws it (colors, the animated
# spinner while busy - tmux animates only inside its own formats).
#   tmux-claude-status.sh <pane_tty>
set -uo pipefail

tty="${1#/dev/}"

shopt -s nullglob
for f in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/sessions/*.json; do
  IFS=$'\t' read -r pid status start < <(
    jq -r 'select(.kind == "interactive") | [.pid, .status, .procStart] | @tsv' "$f" 2>/dev/null
  ) || continue
  [ -n "${pid:-}" ] || continue

  read -r ptty lstart < <(TZ=UTC LC_ALL=C ps -o tty=,lstart= -p "$pid" 2>/dev/null) || continue
  [ "$ptty" = "$tty" ] || continue
  # A crashed Claude leaves its file behind and the pid may since have been
  # recycled: the rec counts only while that pid still has the start time the
  # file recorded. Squeeze spaces - procStart pads a 1-digit day ("Oct  2").
  [ "$(tr -s ' ' <<<"$lstart")" = "$(tr -s ' ' <<<"$start")" ] || continue

  case "$status" in
    busy | idle | waiting) echo "$status" ;;
    *) echo unknown ;;
  esac
  exit 0
done
