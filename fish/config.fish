# PATH: rustup's toolchain and our own scripts (lazygit-claude).
fish_add_path --global --path /opt/homebrew/opt/rustup/bin ~/.local/bin

# Outside the interactive block on purpose: tmux runs popup commands as
# `fish -c "..."` (non-interactive), and those need these too.
set -gx FORCE_COLOR 3
set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1

# No "Welcome to fish" greeting.
set -g fish_greeting

if status is-interactive
    # Prompt.
    starship init fish | source

    # Ghostty: attach to the one tmux session "main" (or create it). Closing
    # Ghostty only detaches, so its windows are back on the next launch.
    # Only in Ghostty - VS Code runs an interactive fish without a terminal
    # to read the environment, and exec tmux would fail there.
    if not set -q TMUX; and test "$TERM_PROGRAM" = ghostty
        exec tmux new-session -A -s main
    end

    # Tab completions with descriptions for 1000+ commands (carapace), loaded
    # on the first Tab rather than at start (functions/__carapace_tab).
    bind tab __carapace_tab

    # fzf: Ctrl+R history, Ctrl+T files.
    set -gx FZF_DEFAULT_OPTS "--tmux 90%,70% --border"
    fzf --fish | source

    # No gray inline suggestions while typing - Tab (carapace) instead.
    set -g fish_autosuggestion_enabled 0

    # Existing paths in the command line are bold, not underlined.
    set -g fish_color_valid_path --bold

    # Tab list (carapace's completions, drawn by fish): options cyan, not bold,
    # so they look like the arguments in the command line (named "cyan" =
    # Ghostty's palette, the same shade); the part already typed bold cyan
    # instead of bold underlined; "…and N more" in calm gray.
    set -g fish_pager_color_prefix --bold cyan
    set -g fish_pager_color_completion cyan
    set -g fish_pager_color_progress 586E75
    # Selected row: dark background instead of inverted
    # colors, text as in the other rows.
    set -g fish_pager_color_selected_background --background=02232B
    set -g fish_pager_color_selected_prefix --bold cyan
    set -g fish_pager_color_selected_completion cyan
    set -g fish_pager_color_selected_description yellow --italics

    alias ll 'eza -la -F --icons=auto --hyperlink=auto --sort=date --reverse --no-filesize --no-time --no-user --git --git-repos'
    alias vim nvim
    alias cc 'claude --continue'
    alias cr 'claude --resume'

    # Functions (c, fish_title, __carapace_tab) live one per file in functions/.
end
