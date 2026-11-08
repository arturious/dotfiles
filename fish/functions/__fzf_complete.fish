# tab completion
function __fzf_complete
    set -l token (commandline -ct)
    set -l candidates (complete -C (commandline -cp))
    set -l result

    switch (count $candidates)
        case 0
            return
        case 1
            set result $candidates[1]
        case '*'
            set result (printf '%s\n' $candidates | \
                fzf --query "$token" --delimiter \t --nth 1 \
                    --prompt (commandline -cp | string trim)" > " \
                    --tmux 70%,50% --border --reverse \
                    --bind "tab:down,btab:up")
            commandline -f repaint
            test -n "$result"; or return
    end

    set result (string split -m1 \t -- $result)[1]
    set -l insert (string escape --no-quoted -- $result)
    # directory
    if not string match -q -- '*/' $result
        set insert "$insert "
    end
    commandline -rt -- $insert
    commandline -f repaint
end
