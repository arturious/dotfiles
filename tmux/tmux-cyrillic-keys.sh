#!/usr/bin/env bash
# Run at the end of settings.conf: copy every prefix binding onto the key's
# Russian (ЙЦУКЕН) letter, so prefix+ц works like prefix+w etc. without
# switching the layout first. Reads the live bindings, so it also covers
# plugins' keys (tmux-claude-hatch, claude-code-cleaner) and future ones.
#
# list-keys prints re-sourceable bind-key lines; swapping just the key and
# sourcing them back keeps every command's quoting exactly as tmux has it.
set -uo pipefail

# Space-separated so awk splits them by letter whether or not it is
# UTF-8 aware.
latin='q w e r t y u i o p a s d f g h j k l z x c v b n m Q W E R T Y U I O P A S D F G H J K L Z X C V B N M [ ] , .'
cyrillic='й ц у к е н г ш щ з ф ы в а п р о л д я ч с м и т ь Й Ц У К Е Н Г Ш Щ З Ф Ы В А П Р О Л Д Я Ч С М И Т Ь х ъ б ю'

conf="${TMPDIR:-/tmp}"
conf="${conf%/}/tmux-cyrillic-keys-$(id -u).conf"

tmux list-keys -T prefix | awk -v latin="$latin" -v cyrillic="$cyrillic" '
  BEGIN {
    n = split(latin, from, " "); split(cyrillic, to, " ")
    for (i = 1; i <= n; i++) map[from[i]] = to[i]
  }
  # bind-key [-r] -T prefix KEY COMMAND... - swap only KEY
  match($0, /-T prefix +/) {
    head = substr($0, 1, RSTART + RLENGTH - 1)
    rest = substr($0, RSTART + RLENGTH)
    key = rest; sub(/ .*/, "", key)
    if (key in map) print head map[key] substr(rest, length(key) + 1)
  }' >"$conf"

tmux source-file "$conf"
