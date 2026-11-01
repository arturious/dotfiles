#!/usr/bin/env bash
# prefix+w / prefix+s: window or session picker with live preview.
#   tmux-picker.sh windows|sessions <#rrggbb>   (color marks the current row)
#   tmux-picker.sh --list windows|sessions <#rrggbb>
#   tmux-picker.sh --preview <target>
set -uo pipefail
self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# display-popup doesn't expand formats, so it can't be passed in.
session=$(tmux display-message -p '#{session_name}')

list() {
  local kind="$1" color="${2:-}" esc mark
  esc=$(printf '\033')
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
    # Drop trailing blank lines, or fzf's `follow` scrolls onto padding.
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
