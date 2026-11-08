#!/usr/bin/env bash
# Sets up a Mac from this repo: Homebrew packages, symlinks into place,
# plugins, login shell, macOS defaults. Idempotent; real files are backed up.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SUPPORT="$HOME/Library/Application Support"

link() {
  local src="$DOTFILES_DIR/$1" dest="$2"

  if [ ! -e "$src" ]; then
    echo "    !! $src not found, skipping"
    return
  fi
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Backing up $dest -> $backup"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"
  echo "    $dest -> $src"
}

# ---------------------------------------------------------------------------
# Homebrew packages
# ---------------------------------------------------------------------------
echo "==> Homebrew"
if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew bundle --file "$DOTFILES_DIR/Brewfile"

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------
echo "==> Symlinks"

# Claude Code: single files, ~/.claude also holds sessions and caches.
link claude/settings.json        "$HOME/.claude/settings.json"
link claude/statusline.py        "$HOME/.claude/statusline.py"
link claude/themes/custom.json   "$HOME/.claude/themes/custom.json"

# Cursor reads settings only from Application Support. ~/.config/cursor also
# holds the Cursor CLI's own files, so link single files there too.
link cursor/settings.json        "$APP_SUPPORT/Cursor/User/settings.json"
link cursor/custom.css           "$HOME/.config/cursor/custom.css"
link cursor/fix.sh               "$HOME/.config/cursor/fix.sh"

# fish: single files, fisher keeps its own functions and completions there.
link fish/config.fish            "$HOME/.config/fish/config.fish"
link fish/fish_plugins           "$HOME/.config/fish/fish_plugins"
for fn in "$DOTFILES_DIR"/fish/functions/*.fish; do
  link "fish/functions/${fn##*/}" "$HOME/.config/fish/functions/${fn##*/}"
done

link ghostty                     "$HOME/.config/ghostty"
link git                         "$HOME/.config/git"
link hammerspoon                 "$HOME/.config/hammerspoon"
# Whole dir: Karabiner doesn't reload on edits behind a symlinked file.
link karabiner                   "$HOME/.config/karabiner"
link lazygit                     "$HOME/.config/lazygit"
link starship/starship.toml      "$HOME/.config/starship.toml"
link tmux                        "$HOME/.config/tmux"

# ---------------------------------------------------------------------------
# Plugins
# ---------------------------------------------------------------------------
echo "==> Cursor extensions"
cursor_bin="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
if [ -x "$cursor_bin" ]; then
  installed="$("$cursor_bin" --list-extensions 2>/dev/null || true)"
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    if ! grep -qixF "$ext" <<<"$installed"; then
      echo "    installing $ext"
      "$cursor_bin" --install-extension "$ext" >/dev/null 2>&1 || echo "    !! could not install $ext"
    fi
  done < "$DOTFILES_DIR/cursor/extensions.txt"
fi

echo "==> TPM"
# ~/.tmux.conf would win over ~/.config/tmux/tmux.conf.
if [ -L "$HOME/.tmux.conf" ]; then
  rm "$HOME/.tmux.conf"
fi
tpm_dir="$HOME/.tmux/plugins/tpm"
if [ ! -d "$tpm_dir" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi
"$tpm_dir/bin/install_plugins"

echo "==> fisher"
fish -c 'if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
end
fisher update'

echo "==> pre-commit (gitleaks)"
(cd "$DOTFILES_DIR" && pre-commit install)

# ---------------------------------------------------------------------------
# System
# ---------------------------------------------------------------------------
echo "==> fish login shell"
fish_path="$(command -v fish || true)"
if [ -n "$fish_path" ] && [ "$SHELL" != "$fish_path" ]; then
  grep -qxF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$fish_path" || echo "    !! chsh failed, run manually: chsh -s \"$fish_path\""
fi

echo "==> macOS defaults"
"$DOTFILES_DIR/macos/defaults.sh"
