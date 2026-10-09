#!/usr/bin/env bash
# Pane-border segment: " ● waiting ──" for the Claude Code running on the
# pane's tty, or nothing when no Claude runs there. Status comes from the files
# Claude itself keeps in ~/.claude/sessions, read the same way tmux-claude-hatch
# does (scripts/agents.sh): same colors, same liveness check. Used by
# pane-border-format in settings.conf.
#   tmux-claude-status.sh <pane_tty> <border_color> <text_color>
set -uo pipefail

tty="${1#/dev/}"
border="${2:-default}"
text_color="${3:-default}"

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

  # ANSI colors, as in the plugin's picker - the exact shade comes from the
  # terminal's palette.
  case "$status" in
    waiting) color=yellow       text='waiting' ;;
    idle)    color=green        text='idle'    ;;
    busy)    color=red          text='working' ;;
    *)       color=brightblack  text='?'       ;;
  esac
  printf ' #[fg=%s]● #[fg=%s]%s #[fg=%s]──' "$color" "$text_color" "$text" "$border"
  exit 0
done
