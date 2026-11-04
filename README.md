# github.com/arturious/dotfiles

My macOS dotfiles, managed with [chezmoi](https://chezmoi.io). The repo root is
the chezmoi source state (layout borrowed from
[craftzdog/dotfiles](https://github.com/craftzdog/dotfiles)); files are
**copied** into `$HOME`, not symlinked.

## New Mac

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply --source ~/dotfiles arturious
```

This installs chezmoi, clones this repo into `~/dotfiles` and applies it.
On a Mac without Homebrew, the first script installs it (and Brewfile's
`chezmoi` replaces the bootstrap binary).

`chezmoi apply` also runs the scripts at the repo root (macOS only):

| Script | When | What |
| --- | --- | --- |
| `run_onchange_before_install-homebrew-packages.sh.tmpl` | Brewfile changed | install Homebrew if missing, `brew bundle` |
| `run_once_after_install-tmux-plugins.sh.tmpl` | once | remove stale `~/.tmux.conf` link, install TPM + plugins |
| `run_once_after_set-fish-login-shell.sh.tmpl` | once | add fish to `/etc/shells` (sudo), `chsh` to fish |
| `run_onchange_after_configure-macos-defaults.sh.tmpl` | script changed | macOS `defaults write` settings, restarts Finder and Dock |
| `run_onchange_after_install-fish-plugins.sh.tmpl` | `fish_plugins` changed | install fisher if missing, `fisher update` |
| `run_onchange_after_link-cursor.sh.tmpl` | extension list changed | symlink Cursor settings, install missing extensions |
| `run_once_after_install-git-hooks.sh.tmpl` | once | `pre-commit install` (gitleaks) in this repo |

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
  ~/.claude/settings.json
```

Run `chezmoi diff` first if unsure which side is newer.

## Structure

| Source | Target |
| --- | --- |
| `dot_claude/` | `~/.claude/` (settings, statusline.py, themes/custom.json) |
| `dot_config/fish/` | `~/.config/fish/` (config.fish, own functions, `fish_plugins` for fisher; `config-local.fish` is machine-only and ignored) |
| `dot_config/git/` | `~/.config/git/` (`config` from a template with name/email from `chezmoi init`, aliases, global `ignore`; `local.gitconfig` is machine-only) |
| `dot_config/private_karabiner/` | `~/.config/karabiner/` (Karabiner backups are ignored) |
| `dot_config/starship.toml` | `~/.config/starship.toml` |
| `dot_config/tmux/` | `~/.config/tmux/` (`tmux.conf` sources theme, options, bindings, plugins, statusline) |
| `bin/` | `~/bin/` (own scripts, on PATH via fish) |
| `dot_config/cursor/` | `~/.config/cursor/` (settings, custom.css, fix.sh, extensions.txt; symlinked into Application Support by a script) |
| `dot_config/hammerspoon/` | `~/.config/hammerspoon/` (MJConfigFile set by the macOS defaults script) |
| `Brewfile` | not deployed, used by the Homebrew script |

`executable_` / `private_` / `dot_` are chezmoi name prefixes; `.chezmoiignore`
lists what stays out of `$HOME`, `.chezmoi.toml.tmpl` becomes
`~/.config/chezmoi/chezmoi.toml` on `chezmoi init`.

## Secrets

`gitleaks` scans every commit through a pre-commit hook (`.pre-commit-config.yaml`)
and every push through GitHub Actions (`.github/workflows/gitleaks.yml`).
Keep tokens in `~/.config/fish/config-local.fish` or `~/.config/git/local.gitconfig`,
which are never committed.

## Cursor

Cursor only reads settings from `~/Library/Application Support/Cursor/User`.
The real files live in `dot_config/cursor/` (deployed to `~/.config/cursor/`) and
`run_onchange_after_link-cursor.sh.tmpl` symlinks `settings.json` (and
`keybindings.json` if added) into Application Support, then installs any
extension from `extensions.txt` that is missing. Settings changed in the Cursor
UI land in `~/.config/cursor/settings.json`; pull them back with `chezmoi re-add`.
Refresh the extension list with
`cursor --list-extensions > ~/.config/cursor/extensions.txt && chezmoi re-add`.
