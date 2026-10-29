fish_add_path --global --path /opt/homebrew/opt/rustup/bin ~/.local/bin

# Outside is-interactive: tmux popups run `fish -c` and need these too.
set -gx FORCE_COLOR 3
set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1

set -g fish_greeting

if status is-interactive
    # Ghostty: attach to the one tmux session "main" (or create it); closing
    # Ghostty only detaches. Not in VS Code: its fish has no terminal for tmux.
    if not set -q TMUX; and test "$TERM_PROGRAM" = ghostty
        exec tmux new-session -A -s main
    end

    starship init fish | source

    bind tab __carapace_tab

    set -gx FZF_DEFAULT_OPTS "--tmux 90%,70% --border"
    fzf --fish | source

    set -g fish_autosuggestion_enabled 0
    set -g fish_color_valid_path --bold

    # Completion pager: "cyan" is Ghostty's palette color, same as arguments.
    set -g fish_pager_color_prefix --bold cyan
    set -g fish_pager_color_completion cyan
    set -g fish_pager_color_progress 586E75
    set -g fish_pager_color_selected_background --background=02232B
    set -g fish_pager_color_selected_prefix --bold cyan
    set -g fish_pager_color_selected_completion cyan
    set -g fish_pager_color_selected_description yellow --italics

    zoxide init fish | source

    alias ll 'eza -la -F --icons=auto --hyperlink=auto --sort=date --reverse --no-filesize --no-time --no-user --git --git-repos'
    alias vim nvim
    alias cc 'claude --continue'
    alias cr 'claude --resume'

    # Cloudflare WARP SOCKS5 proxy
    function warp
        cd ~/warp; and ./wireproxy -c wgcf-profile.conf
    end
end
