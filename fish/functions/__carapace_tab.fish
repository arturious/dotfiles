# lazy carapace
function __carapace_tab
    bind tab __fzf_complete
    carapace _carapace fish | source
    __fzf_complete
end
