# Called by fish itself right before the first prompt of an interactive
# shell (replaces the built-in "Welcome to fish" greeting).
#
# Warp-style animated welcome screen (../greeting/greeting.py) in every new
# tmux window - Ghostty launch and Cmd+T both land here - but not in splits:
# only when this pane is the window's only one.
function fish_greeting
    set -q TMUX; or return
    test (tmux display -p -t "$TMUX_PANE" '#{window_panes}') = 1; or return

    # This file is symlinked into ~/.config/fish/functions; resolve it to find
    # greeting/ next to it in dotfiles.
    set -l dir (path dirname (path resolve (status current-filename)))
    python3 $dir/../greeting/greeting.py
end
