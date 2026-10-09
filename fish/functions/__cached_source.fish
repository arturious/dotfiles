# __cached_source NAME COMMAND ARGS... - source the fish code COMMAND prints
# (starship / fzf / carapace init), from a cache file instead of running it on
# every shell start: each run took 10-40ms, delaying the greeting on Cmd+T.
# The cache is rebuilt when the command's binary changes - keyed on its
# resolved path (/opt/homebrew/Cellar/<name>/<version>/...), not its mtime,
# since Homebrew bottles keep their build-time mtimes.
function __cached_source
    set -l name $argv[1]
    set -l cmd $argv[2..]
    set -l bin (command -s $cmd[1]); or return
    set -l key "# "(path resolve $bin)
    set -l cache (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo ~/.cache)/fish/$name.fish

    set -l first
    test -f $cache; and read -l first <$cache
    if test "$first" != "$key"
        mkdir -p (path dirname $cache)
        begin
            echo $key
            $cmd
        end >$cache
    end
    source $cache
end
