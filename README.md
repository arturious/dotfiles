# github.com/arturious/dotfiles

My macOS dotfiles, managed with [chezmoi](https://chezmoi.io). The repo root is
the chezmoi source state (layout borrowed from
[craftzdog/dotfiles](https://github.com/craftzdog/dotfiles)); files are
**copied** into `$HOME`, not symlinked.

## New Mac

```sh
git clone https://github.com/arturious/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` installs Homebrew (if missing) and chezmoi, then runs
`chezmoi init --apply --source ~/dotfiles`. Without a checkout the same is:

```sh
chezmoi init --apply arturious   # clones into ~/.local/share/chezmoi
```

`chezmoi apply` also runs the scripts at the repo root (macOS only):

| Script | When | What |
| --- | --- | --- |
| `run_onchange_before_install-homebrew-packages.sh.tmpl` | Brewfile changed | install Homebrew if missing, `brew bundle` |
| `run_once_after_install-tmux-plugins.sh.tmpl` | once | remove stale `~/.tmux.conf` link, install TPM + plugins |
| `run_once_after_set-fish-login-shell.sh.tmpl` | once | add fish to `/etc/shells` (sudo), `chsh` to fish |
| `run_onchange_after_configure-macos-defaults.sh.tmpl` | `macos/defaults.sh` changed | run `macos/defaults.sh` (restarts Finder and Dock) |

## Day to day

```sh
chezmoi edit ~/.config/fish/config.fish   # opens the source in Cursor, applies on close
chezmoi diff                              # what apply would change
chezmoi apply                             # write source -> $HOME
chezmoi cd                                # git commit / push from the source dir
```

`cz` is a fish abbreviation for `chezmoi`.

Some apps rewrite their own config. After changing settings in the app, pull
the file back into the repo before the next `apply` overwrites it:

```sh
chezmoi re-add   # all managed files, or name them:
chezmoi re-add ~/.config/karabiner/karabiner.json \
  "$HOME/Library/Application Support/Cursor/User/settings.json" \
  "$HOME/Library/Application Support/Code/User/settings.json" \
  ~/.claude/settings.json
```

Run `chezmoi diff` first if unsure which side is newer.

## Structure

| Source | Target |
| --- | --- |
| `dot_claude/` | `~/.claude/` (settings, statusline.py, themes/custom.json) |
| `dot_config/fish/` | `~/.config/fish/` (config.fish + own functions; fisher's files are left alone) |
| `dot_config/private_karabiner/` | `~/.config/karabiner/` (Karabiner backups are ignored) |
| `dot_config/starship.toml` | `~/.config/starship.toml` |
| `dot_config/tmux/` | `~/.config/tmux/` |
| `dot_cursor/` | `~/.cursor/` (custom.css, fix.sh) |
| `dot_hammerspoon/` | `~/.hammerspoon/` |
| `private_Library/private_Application Support/` | `~/Library/Application Support/` (Cursor, Code, Ghostty, lazygit) |
| `Brewfile` | not deployed, used by the Homebrew script |
| `macos/defaults.sh` | not deployed, run by the defaults script |
| `userscripts/` | not deployed, browser userscripts installed from the raw GitHub URL |

`executable_` / `private_` / `dot_` are chezmoi name prefixes; `.chezmoiignore`
lists what stays out of `$HOME`, `.chezmoi.toml.tmpl` becomes
`~/.config/chezmoi/chezmoi.toml` on `chezmoi init`.
