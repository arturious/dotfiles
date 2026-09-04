set -g fish_greeting

if status is-interactive
    starship init fish | source

    if not set -q TMUX
        if tmux has-session -t main 2>/dev/null
            exec tmux new-session -t main \; new-window
        else
            exec tmux new-session -s main
        end
    end

    set -gx FORCE_COLOR 3
    set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1
    set -gx FZF_DEFAULT_OPTS "--tmux 90%,70% --border"
    source /opt/homebrew/opt/fzf/shell/key-bindings.fish
    fzf_key_bindings
end
export PATH="$HOME/.local/bin:$PATH"
