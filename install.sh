#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# iTerm2
# ---------------------------------------------------------------------------
install_iterm2() {
  echo "==> iTerm2"

  local prefs_dir="$DOTFILES_DIR/iterm2"

  if [ ! -f "$prefs_dir/com.googlecode.iterm2.plist" ]; then
    echo "    !! $prefs_dir/com.googlecode.iterm2.plist not found, skipping"
    return
  fi

  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$prefs_dir"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

  echo "    iTerm2 prefs now point to: $prefs_dir"
  echo "    Restart iTerm2 (Cmd+Q) to apply the settings"
}

# ---------------------------------------------------------------------------
# Karabiner-Elements
# ---------------------------------------------------------------------------
install_karabiner() {
  echo "==> Karabiner-Elements"

  local src="$DOTFILES_DIR/karabiner"
  local dest="$HOME/.config/karabiner"

  if [ ! -d "$src" ]; then
    echo "    !! $src not found, skipping"
    return
  fi

  if [ -L "$dest" ]; then
    echo "    $dest is already a symlink, skipping"
    return
  fi

  if [ -e "$dest" ]; then
    local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Existing $dest found, backing up to $backup"
    mv "$dest" "$backup"
  fi

  mkdir -p "$HOME/.config"
  ln -s "$src" "$dest"

  echo "    Symlinked $dest -> $src"
}

# ---------------------------------------------------------------------------
# VS Code
# ---------------------------------------------------------------------------
install_vscode() {
  echo "==> VS Code"

  local src="$DOTFILES_DIR/vscode/settings.json"
  local dest="$HOME/Library/Application Support/Code/User/settings.json"

  if [ ! -f "$src" ]; then
    echo "    !! $src not found, skipping"
    return
  fi

  if [ -L "$dest" ]; then
    echo "    $dest is already a symlink, skipping"
    return
  fi

  if [ -e "$dest" ]; then
    local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Existing $dest found, backing up to $backup"
    mv "$dest" "$backup"
  fi

  mkdir -p "$HOME/Library/Application Support/Code/User"
  ln -s "$src" "$dest"

  echo "    Symlinked $dest -> $src"
}

# ---------------------------------------------------------------------------
# Add new install_<app> functions below and call them here
# ---------------------------------------------------------------------------

install_iterm2
install_karabiner
install_vscode
