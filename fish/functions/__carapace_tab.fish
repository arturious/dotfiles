# Loads carapace (~40ms) on the first Tab instead of at shell start,
# then hands Tab to the fzf picker (__fzf_complete).
function __carapace_tab
    bind tab __fzf_complete
    carapace _carapace fish | source
    __fzf_complete
end
