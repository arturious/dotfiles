function fish_user_key_bindings
    # fzf (Ctrl+R history, Ctrl+T files, Alt+C cd come from `fzf --fish`)
    bind ctrl-f __fzf_change_directory
    bind ctrl-o '__fzf_search files'
    bind ctrl-alt-l '__fzf_search git_log'
    bind ctrl-alt-s '__fzf_search git_status'
    bind ctrl-alt-p '__fzf_search processes'
    bind ctrl-v '__fzf_search variables'

    # Ctrl+D deletes a character instead of closing the shell (EOF).
    bind ctrl-d delete-char
end
