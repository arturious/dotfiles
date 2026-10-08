# Terminal/pane title (#T in the tmux tab pills): same as fish's built-in
# fish_title, but only the last folder name instead of prompt_pwd's
# "~/dev" - just "dev" (still "~" at home).
function fish_title
    set -l dir (path basename -- $PWD)
    test "$PWD" = "$HOME"; and set dir '~'
    set -l command $argv[1]
    if not set -q argv[1]
        set command (status current-command)
        test "$command" = fish; and set command
    end
    echo -- (string sub -l 20 -- $command) $dir
end
