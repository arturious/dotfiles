#!/usr/bin/env bash
# prefix+w (see settings.conf): window picker in a popup, styled after
# tmux-claude-hatch's agent picker (prefix+u) - live preview of each window
# on top, the list below.
#
#   tmux-window-picker.sh                       the fzf picker
#   tmux-window-picker.sh --list <session>      print the rows
#   tmux-window-picker.sh --preview <window>    capture the window's active pane
#
#   Row: window_id \t INDEX \t NAME \t PATH   (only the last three are shown)
set -uo pipefail
self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

if [ "${1:-}" = --list ]; then
  esc=$(printf '\033')
  tmux list-windows -t "${2:-}:" -F \
    "#{window_id}	#{?window_active,${esc}[38;2;39;139;210m,}#{window_index}${esc}[0m	#{window_name}	#{pane_current_path}" |
    sed "s|	$HOME|	~|"
  exit 0
fi

if [ "${1:-}" = --preview ]; then
  # Without its trailing blank lines, which would otherwise leave fzf's
  # `follow` scrolled onto padding (same as tmux-claude-hatch's preview).
  tmux capture-pane -ept "${2:-}" 2>/dev/null |
    awk -v esc="$(printf '\033')" '
      { line = $0; gsub(esc "\\[[0-9;]*m", "", line) }
      line ~ /^[[:space:]]*$/ { held = held $0 "\n"; next }
      { printf "%s", held; held = ""; print }
    '
  exit 0
fi

# The popup's own session (display-popup doesn't expand formats in its
# command, so it can't be passed in).
session=$(tmux display-message -p '#{session_name}')
export FZF_DEFAULT_OPTS=''

# Start on the current window.
pos=$(tmux list-windows -t "$session:" -F '#{window_active}' | grep -n 1 | cut -d: -f1)

sel=$("$self" --list "$session" | fzf --ansi --delimiter='\t' --with-nth=2,3,4 \
  --reverse --cycle --header='Windows · enter: switch · ctrl-x: kill' \
  --preview="$self --preview {1}" --preview-window='up,70%,follow' \
  --bind="load:pos(${pos:-1})" \
  --bind="ctrl-x:execute-silent(tmux kill-window -t {1})+reload($self --list $session)" \
  --bind='change:first')

[ -n "$sel" ] && tmux select-window -t "$(printf '%s' "$sel" | cut -f1)"
exit 0
