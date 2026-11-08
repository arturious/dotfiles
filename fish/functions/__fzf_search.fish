# fzf pickers bound in fish_user_key_bindings.fish; each inserts what was
# picked at the cursor.
#   files       Ctrl+O      files and folders here, preview with bat / eza
#   git_log     Ctrl+Alt+L  commits, preview the diff with delta; inserts hashes
#   git_status  Ctrl+Alt+S  changed files, preview the diff (bat if untracked)
#   processes   Ctrl+Alt+P  running processes; inserts PIDs
#   variables   Ctrl+V      shell variables, values in the preview; inserts names
function __fzf_search -a mode
    switch $mode
        case files
            set -l picked (fd --hidden --exclude .git --color=always . | \
                fzf --ansi --multi --query (commandline -ct) \
                    --preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || eza -la --icons=auto --color=always {}')
            and commandline -rt -- (string escape -- $picked | string join ' ')' '

        case git_log
            git rev-parse --git-dir >/dev/null 2>&1; or return
            set -l picked (git log --no-show-signature --color=always --date=short \
                --format='%C(bold blue)%h%C(reset) %C(cyan)%ad%C(reset)%C(yellow)%d%C(reset) %s %C(dim)[%an]%C(reset)' | \
                fzf --ansi --multi --no-sort --reverse \
                    --preview 'git show {1} | delta --paging=never')
            and commandline -it -- (string split -f1 ' ' $picked | string join ' ')' '

        case git_status
            git rev-parse --git-dir >/dev/null 2>&1; or return
            set -l picked (git -c color.status=always status --short | \
                fzf --ansi --multi --nth 2.. \
                    --preview 'git diff --quiet HEAD -- {-1} && bat --style=numbers --color=always {-1} || git diff HEAD -- {-1} | delta --paging=never')
            # "XY path" or "XY old -> new": keep the (new) path.
            and set -l paths (string sub -s 4 -- $picked | string replace -r '.* -> ' '')
            and commandline -it -- (string escape -- $paths | string join ' ')' '

        case processes
            set -l picked (ps -A -o pid,command | \
                fzf --multi --header-lines 1 --nth 2.. \
                    --preview 'ps -o pid,ppid,user,%cpu,%mem,start,command -p {1}' \
                    --preview-window 'down,4,wrap')
            and commandline -it -- (string trim -- $picked | string split -f1 ' ' | string join ' ')' '

        case variables
            set -l dump (mktemp)
            set --show >$dump
            set -l picked (set --names | \
                fzf --multi --query (commandline -ct) \
                    --preview "grep -E '^\\\$'{}'(:|\\[)' $dump")
            and commandline -rt -- (string join ' ' $picked)' '
            rm -f $dump
    end
    commandline -f repaint
end
