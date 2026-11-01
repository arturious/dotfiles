# Built-in fish_title, but with only the last folder name ("~" at home).
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
