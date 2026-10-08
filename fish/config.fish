# rustup's toolchain, then our own scripts (lazygit-claude) in
# ~/.local/bin. fish_add_path skips entries already in $PATH, so no
# duplicates however many times this file is sourced.
fish_add_path --global --path /opt/homebrew/opt/rustup/bin ~/.local/bin

# Not inside `if status is-interactive` on purpose: tmux runs a popup/pane's
# command as `fish -c "..."`, which is non-interactive, so anything in that
# block (e.g. tmux-claude-hatch's popups) would never see these. Harmless to
# set unconditionally either way.
set -gx FORCE_COLOR 3
set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1

if status is-interactive
    starship init fish | source

    # Only in Ghostty: VS Code resolves the environment by running an
    # interactive login fish without a terminal, where exec tmux fails
    # ("not a terminal") and VS Code reports "Unable to resolve your shell
    # environment". Its integrated terminal stays plain fish too.
    if not set -q TMUX; and test "$TERM_PROGRAM" = ghostty
        if tmux has-session -t main 2>/dev/null
            exec tmux new-session -t main \; new-window
        else
            exec tmux new-session -s main
        end
    end

    # Functions (c, fish_greeting, fish_title, __fzf_tab_complete) live one
    # per file in functions/, autoloaded on first use.
    set -g fish_autosuggestion_enabled 0

    alias ll 'eza -la -F --icons=auto --hyperlink=auto --sort=date --reverse --no-filesize --no-time --no-user --git --git-repos'
    alias vim nvim
    alias cc 'claude --continue'
    alias cr 'claude --resume'

    set -gx FZF_DEFAULT_OPTS "--tmux 90%,70% --border"
    source /opt/homebrew/opt/fzf/shell/key-bindings.fish
    fzf_key_bindings

    # Tab completion as an fzf popup (functions/__fzf_tab_complete.fish).
    bind \t __fzf_tab_complete
end
