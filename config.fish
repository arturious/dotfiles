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

    set -g fish_autosuggestion_enabled 0

    set -gx FORCE_COLOR 3
    set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1
    set -gx FZF_DEFAULT_OPTS "--tmux 90%,70% --border"
    source /opt/homebrew/opt/fzf/shell/key-bindings.fish
    fzf_key_bindings

    # Show Ghostty's OSC 9;4 progress bar (indeterminate) for any command
    # still running after 1s (matches config.ghostty's
    # notify-on-command-finish-after). Skip `claude` — it drives its own
    # progress bar per-turn (terminalProgressBarEnabled) and would otherwise
    # look permanently "busy" for the whole session, since fish sees it as
    # one long-running command.
    function __progress_preexec --on-event fish_preexec
        if string match -qr '^\s*claude(\s|$)' -- $argv[1]
            return
        end
        set -g __progress_token (date +%s%N)
        set -l marker /tmp/.fish-progress-$fish_pid
        echo $__progress_token >$marker
        fish -c "sleep 1; if test -f $marker; and test (cat $marker) = $__progress_token; printf '\033]9;4;3;\007'; end" &
        disown
    end

    function __progress_postexec --on-event fish_postexec
        rm -f /tmp/.fish-progress-$fish_pid
        printf '\033]9;4;0;0\007'
    end

    # Tab completion as an fzf popup (bordered, via $FZF_DEFAULT_OPTS above)
    # instead of fish's plain inline pager. 0 or 1 match: behave like normal
    # Tab. 2+: pick from the fzf popup.
    function __fzf_tab_complete
        set -l cmd (commandline -cp)
        set -l completions (complete -C "$cmd")
        if test (count $completions) -le 1
            commandline -f complete
            return
        end
        # fzf's default tiebreak (length) measures the *whole* line, so a
        # short match with a long description (e.g. `upgrade`) loses to a
        # longer match with a short description (e.g. `update-if-needed`).
        # Pre-sort by the value's own length and pin ties to that order.
        set -l sorted (printf '%s\n' $completions | awk -F'\t' '{print length($1)"\t"$0}' | sort -t\t -k1,1n | cut -f2-)
        # Field 1 is the padded value (matched via --nth 1 AND displayed —
        # no --with-nth here: it previously flattened both fields into one
        # before --nth could apply, so descriptions were matched too, e.g.
        # searching "GitHub" — only in `update`'s description — still hit).
        # Field 2 is the comment-gray description, display-only by virtue of
        # not being searched, not by being hidden. Colors from Solarized Dark
        # Patched (config.ghostty): cyan #259286, comment #475b62 — bg forced
        # to pure black instead of the theme's own dark-teal background.
        set -l display (printf '%s\n' $sorted | awk -F'\t' '{printf "%-28s\t\033[38;2;71;91;98m%s\033[0m\n", $1, $2}')
        set -l choice (printf '%s\n' $display | fzf --layout=reverse --ansi --delimiter '\t' --nth 1 --tiebreak=index --preview-window hidden --info hidden \
            --color 'fg:#259286,bg:#000000,hl:#a57706,fg+:#819090,bg+:#002831,hl+:#c61c6f,border:#475b62,label:#259286,prompt:#738a05,pointer:#d11c24,marker:#738a05,info:#475b62,query:#708284')
        if test -n "$choice"
            commandline -t -- (string trim -- (string split -m1 \t -- $choice)[1])
        end
        commandline -f repaint
    end
    bind \t __fzf_tab_complete
end
export PATH="$HOME/.local/bin:$PATH"
