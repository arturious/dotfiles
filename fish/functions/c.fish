# `c` alone opens interactive claude; `c how do I undo a commit` runs a
# one-shot `claude -p "..."` with all the words joined into one prompt.
function c
    if not set -q argv[1]
        claude
        return
    end
    if not isatty stderr
        claude -p "$argv"
        return
    end

    set -l out (mktemp)
    set -l rc (mktemp)
    # sh + disown instead of a fish job: no "Job 1 has ended" message.
    sh -c 'claude -p "$1" >"$2" 2>&1; echo $? >"$3"' _ "$argv" $out $rc &
    set -l pid $last_pid
    disown $pid

    # Ctrl+C: claude is a child of the sh wrapper, so kill it explicitly.
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
