#!/usr/bin/env bash
# Pane-border segment: "‹ :3000 ›──" for TCP ports that processes on the pane's
# tty are listening on (e.g. a dev server), or nothing when none. Used by
# pane-border-format in settings.conf.
#   tmux-pane-port.sh <pane_tty> <border_color> <port_color>
set -uo pipefail

tty="${1#/dev/}"
border="${2:-default}"
port_color="${3:-default}"
L=$'' R=$''

pids=$(ps -t "$tty" -o pid= 2>/dev/null | tr -d ' ' | paste -sd, -)
[ -n "$pids" ] || exit 0

ports=$(lsof -nP -a -p "$pids" -iTCP -sTCP:LISTEN -Fn 2>/dev/null |
  sed -n 's/^n.*:\([0-9][0-9]*\)$/\1/p' | sort -un | sed 's/^/:/' | paste -sd' ' -)
[ -n "$ports" ] || exit 0

printf '%s #[fg=%s]%s #[fg=%s]%s──' "$L" "$port_color" "$ports" "$border" "$R"
