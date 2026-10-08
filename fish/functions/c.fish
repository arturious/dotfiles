# `c` alone opens interactive claude; `c how do I undo a commit` runs a
# one-shot `claude -p "..."` with all the words joined into one prompt.
function c
    if not set -q argv[1]
        claude
        return
    end
    # No spinner when stderr isn't a terminal (e.g. `c ... 2>log`).
    if not isatty stderr
        claude -p "$argv"
        return
    end

    set -l out (mktemp)
    set -l rc (mktemp)
    # Run via sh + disown rather than a plain fish `&` job, so fish
    # doesn't print "Job 1 has ended" once it finishes; the exit code
    # comes back through $rc instead of `wait`.
    sh -c 'claude -p "$1" >"$2" 2>&1; echo $? >"$3"' _ "$argv" $out $rc &
    set -l pid $last_pid
    disown $pid

    # Ctrl+C stops the spinner loop - kill claude too, not just the loop.
    # $pid is the sh wrapper; claude is its child and wouldn't get the signal.
    function __c_cancel --on-signal SIGINT --inherit-variable pid --inherit-variable out --inherit-variable rc
        pkill -P $pid 2>/dev/null
        kill $pid 2>/dev/null
        printf '\r\e[K' >&2
        rm -f $out $rc
        functions -e __c_cancel
    end

    set -l frames · ✢ ✳ ✶ ✻ ✽ ✽ ✻ ✶ ✳ ✢ ·
    set -l i 1
    while kill -0 $pid 2>/dev/null
        printf '\r\e[38;2;215;119;87m%s\e[0m' $frames[$i] >&2
        set i (math "$i % "(count $frames)" + 1")
        sleep 0.12
    end
    printf '\r\e[K' >&2
    functions -e __c_cancel

    cat $out
    set -l code (cat $rc 2>/dev/null; or echo 1)
    rm -f $out $rc
    return $code
end
