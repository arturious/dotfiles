#!/usr/bin/env bash
# Copies every live prefix binding onto its ЙЦУКЕН letter (prefix+ц = prefix+w).
# Re-sourcing list-keys output keeps tmux's own quoting intact.
set -uo pipefail

# Space-separated: works with non-UTF-8 awk.
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
