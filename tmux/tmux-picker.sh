#!/usr/bin/env bash
# prefix+w / prefix+s (see settings.conf): window or session picker in a popup,
# styled after tmux-claude-hatch's agent picker (prefix+u) - live preview on
# top, the list below.
#
#   tmux-picker.sh windows|sessions <color>     the fzf picker; <color> (#rrggbb)
#                                               marks the current row
#   tmux-picker.sh --list windows|sessions <color>
#   tmux-picker.sh --preview <target>           capture a window / session's
#                                               active pane
#
#   Row: target \t columns shown in the list...
set -uo pipefail
self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# The popup's own session (display-popup doesn't expand formats in its
# command, so it can't be passed in).
session=$(tmux display-message -p '#{session_name}')

list() {
  local kind="$1" color="${2:-}" esc mark
  esc=$(printf '\033')
  # #rrggbb -> 24-bit ANSI foreground
  mark="${esc}[38;2;$((16#${color:1:2}));$((16#${color:3:2}));$((16#${color:5:2}))m"
  if [ "$kind" = sessions ]; then
    tmux list-sessions -F \
      "#{session_id}	#{?#{==:#{session_name},$session},$mark,}#{session_name}${esc}[0m	#{session_windows} win	#{pane_current_path}"
  else
    tmux list-windows -t "$session:" -F \
      "#{window_id}	#{?window_active,$mark,}#{window_index}${esc}[0m	#{window_name}	#{pane_current_path}"
  fi | sed "s|	$HOME|	~|"
}

case "${1:-}" in
  --list) list "${2:-}" "${3:-}"; exit 0 ;;
  --preview)
    # Without its trailing blank lines, which would otherwise leave fzf's
    # `follow` scrolled onto padding (same as tmux-claude-hatch's preview).
    tmux capture-pane -ept "${2:-}" 2>/dev/null |
      awk -v esc="$(printf '\033')" '
        { line = $0; gsub(esc "\\[[0-9;]*m", "", line) }
        line ~ /^[[:space:]]*$/ { held = held $0 "\n"; next }
        { printf "%s", held; held = ""; print }
      '
    exit 0 ;;
esac

kind="${1:-windows}" color="${2:-#278BD3}"
export FZF_DEFAULT_OPTS=''

if [ "$kind" = sessions ]; then
  # "$id:" = the session's current window, its active pane.
  preview_target='{1}:'
  header='Sessions · enter: switch · ctrl-x: kill'
  pos=$(tmux list-sessions -F '#{session_name}' | grep -nxF "$session" | cut -d: -f1)
  kill='tmux kill-session -t {1}'
  jump() { tmux switch-client -t "$1"; }
else
  preview_target='{1}'
  header='Windows · enter: switch · ctrl-x: kill'
  pos=$(tmux list-windows -t "$session:" -F '#{window_active}' | grep -n 1 | cut -d: -f1)
  kill='tmux kill-window -t {1}'
  jump() { tmux select-window -t "$1"; }
fi

sel=$("$self" --list "$kind" "$color" | fzf --ansi --delimiter='\t' --with-nth=2.. \
  --reverse --cycle --header="$header" \
  --preview="$self --preview $preview_target" --preview-window='up,70%,follow' \
  --bind="load:pos(${pos:-1})" \
  --bind="ctrl-x:execute-silent($kill)+reload($self --list $kind '$color')" \
  --bind='change:first')

[ -n "$sel" ] && jump "$(printf '%s' "$sel" | cut -f1)"
exit 0
