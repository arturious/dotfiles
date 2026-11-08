# dotfiles

My macOS configs, one folder per app. `install.sh` symlinks them into place,
so editing a file here or in the app changes the same file.

## Install

```sh
git clone https://github.com/arturious/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

Safe to re-run. It installs Homebrew and the `Brewfile`, creates the symlinks
(backing up any real file in the way), installs tmux, fish and Cursor plugins,
the gitleaks pre-commit hook, sets fish as the login shell and applies
`macos/defaults.sh`.

## Layout

| Folder | Linked to |
| --- | --- |
| `claude/` | `~/.claude/` (settings, statusline, theme; single files) |
| `cursor/` | `settings.json` into `~/Library/Application Support/Cursor/User/`, `custom.css` and `fix.sh` into `~/.config/cursor/` |
| `fish/` | `~/.config/fish/` (config, functions, `fish_plugins`; single files) |
| `ghostty/` | `~/.config/ghostty` |
| `git/` | `~/.config/git` |
| `hammerspoon/` | `~/.config/hammerspoon` |
| `karabiner/` | `~/.config/karabiner` |
| `lazygit/` | `~/.config/lazygit` |
| `starship/` | `~/.config/starship.toml` |
| `tmux/` | `~/.config/tmux` |
| `macos/` | not linked, `defaults.sh` is run by `install.sh` |

A new file in an already linked folder works as is. A new app, or a new file in
`claude/`, `cursor/` or `fish/`: add a `link` line to `install.sh` and re-run it.

## Machine-only

Not committed: `~/.config/fish/config-local.fish` and `git/local.gitconfig`.
gitleaks checks every commit and push for secrets.
