# First Tab in a shell: load carapace's completions (1000+ commands, with
# descriptions) and complete. Loading them takes ~40ms, so it happens here
# instead of on every shell start; afterwards Tab is plain `complete` again.
function __carapace_tab
    bind tab complete
    carapace _carapace fish | source
    commandline -f complete
end
