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
        # Attach to the one session "main" (or create it): closing Ghostty
        # only detaches, so its windows - and the window you were on - are
        # back on the next launch.
        exec tmux new-session -A -s main
    end

    set -g fish_autosuggestion_enabled 0

    # Existing paths in the command line (e.g. after cd) are bold instead of
    # fish's default underline.
    set -g fish_color_valid_path --bold

    alias ll 'eza -la -F --icons=auto --hyperlink=auto --sort=date --reverse --no-filesize --no-time --no-user --git --git-repos'
    alias vim nvim
    alias cc 'claude --continue'
    alias cr 'claude --resume'

    set -gx FZF_DEFAULT_OPTS "--tmux 90%,70% --border"
    fzf --fish | source

    # Functions (c, fish_greeting, fish_title) live one per file in
    # functions/, autoloaded on use.
end

# inshellisense: IDE-style completion list under the cursor while typing
# (config: inshellisense/rc.toml). It runs this shell inside itself, so it
# must stay the last thing here; the outer fish waits for it and exits with it.
# Skipped outside tmux (Ghostty's first fish execs tmux above anyway) and by
# its own ISTERM check inside the session it starts.
if status is-interactive; and set -q TMUX
    test -f ~/.local/share/inshellisense/init/fish/init.fish
    and source ~/.local/share/inshellisense/init/fish/init.fish
end
