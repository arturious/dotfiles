# Loads carapace (~40ms) on the first Tab instead of at shell start.
function __carapace_tab
    bind tab complete
    carapace _carapace fish | source
    commandline -f complete
end
