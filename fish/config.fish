# path
fish_add_path --global --move --path /opt/homebrew/bin
fish_add_path --global --path ~/.local/bin ~/bin

# env
set -gx FORCE_COLOR 3
set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1
set -gx XDG_CONFIG_HOME $HOME/.config

# greeting
set -g fish_greeting

if status is-interactive
    # tmux
    if not set -q TMUX; and test "$TERM_PROGRAM" = ghostty
        exec tmux new-session -A -s main
    end

    # prompt
    starship init fish | source

    # completion
    bind tab __carapace_tab
    set -g fish_autosuggestion_enabled 0
    set -g fish_color_valid_path --bold

    # fzf
    set -gx FZF_DEFAULT_OPTS "--tmux 90%,70% --border"
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    fzf --fish | source

    # bat
    set -gx BAT_THEME "Solarized (dark)"
    alias less bat

    # zoxide
    zoxide init fish | source

    # aliases
    alias ll 'eza -la -F --icons=auto --hyperlink=auto --sort=date --reverse --no-filesize --no-time --no-user --git --git-repos'
    command -qv nvim && alias vim nvim
    alias g git

    # abbreviations
    abbr -a cc 'claude --continue'
    abbr -a cr 'claude --resume'

    # spotify
    function spotify
        curl -sSL https://spotx-official.github.io/run.sh | bash -s -- $argv
    end

    # warp
    function warp
        cd ~/warp; and ./wireproxy -c wgcf-profile.conf
    end
end

# local
set -l LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
    source $LOCAL_CONFIG
end
