# Called by fish itself right before the first prompt of an interactive
# shell (replaces the built-in "Welcome to fish" greeting) - and earlier, at
# the top of config.fish, so it shows up before the rest of the config loads.
#
# Warp-style animated welcome screen (../greeting/greeting.py) in every new
# tmux window - Ghostty launch and Cmd+T / prefix+c - but not in splits: tmux
# sets TMUX_GREET=1 only for new windows (tmux/settings.conf). Erased once
# used, so the second call and any fish started later in the pane skip it.
function fish_greeting
    set -q TMUX_GREET; or return
    set -e TMUX_GREET

    # This file is symlinked into ~/.config/fish/functions; resolve it to find
    # greeting/ next to it in dotfiles.
    set -l dir (path dirname (path resolve (status current-filename)))
    python3 $dir/../greeting/greeting.py
end
