# Ctrl+F: jump to a project. Lists ~/.config, ghq repos, gwq worktrees,
# subfolders here and ~/dev/*, picked in fzf.
function __fzf_change_directory
    begin
        echo $HOME/.config
        command -q ghq; and ghq list -p
        set -l worktrees (command -q gwq; and gwq config get worktree.basedir | string replace '~' $HOME)
        test -d "$worktrees"; and fd . $worktrees -t d --max-depth 3 --min-depth 3
        fd . -t d --max-depth 1 --exclude .git | string replace -r '^\./' '' | string replace -r '^' "$PWD/"
        fd . $HOME/dev -t d --max-depth 1 --exclude .ghq --exclude gwq
    end | string replace -r '/$' '' | awk '!a[$0]++' | fzf --layout reverse | read -l dir
    if test -n "$dir"
        builtin cd $dir
    end
    commandline -f repaint
end
