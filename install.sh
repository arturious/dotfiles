#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$DOTFILES_DIR/brew.sh"

# ---------------------------------------------------------------------------
# Karabiner-Elements
# ---------------------------------------------------------------------------
install_karabiner() {
  echo "==> Karabiner-Elements"

  local src="$DOTFILES_DIR/karabiner.json"
  local config_dir="$HOME/.config/karabiner"
  local dest="$config_dir/karabiner.json"

  if [ ! -f "$src" ]; then
    echo "    !! $src not found, skipping"
    return
  fi

  mkdir -p "$config_dir"

  if [ -L "$dest" ]; then
    echo "    $dest is already a symlink, skipping"
    return
  fi

  if [ -e "$dest" ]; then
    local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Existing $dest found, backing up to $backup"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"

  echo "    Symlinked $dest -> $src"
}

# ---------------------------------------------------------------------------
# VS Code
# ---------------------------------------------------------------------------
install_vscode() {
  echo "==> VS Code"

  local src="$DOTFILES_DIR/settings.json"
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

  local extensions_file="$DOTFILES_DIR/extensions.txt"
  if command -v code >/dev/null 2>&1 && [ -f "$extensions_file" ]; then
    echo "    Installing VS Code extensions..."
    while IFS= read -r extension; do
      [ -z "$extension" ] && continue
      code --install-extension "$extension"
    done < "$extensions_file"
  fi
}

# ---------------------------------------------------------------------------
# Starship
# ---------------------------------------------------------------------------
install_starship() {
  echo "==> Starship"

  local src="$DOTFILES_DIR/starship.toml"
  local dest="$HOME/.config/starship.toml"

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

  mkdir -p "$HOME/.config"
  ln -s "$src" "$dest"

  echo "    Symlinked $dest -> $src"
}

# ---------------------------------------------------------------------------
# Ghostty
# ---------------------------------------------------------------------------
install_ghostty() {
  echo "==> Ghostty"

  local src="$DOTFILES_DIR/config.ghostty"
  local config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
  local dest="$config_dir/config.ghostty"

  if [ ! -f "$src" ]; then
    echo "    !! $src not found, skipping"
    return
  fi

  mkdir -p "$config_dir"

  if [ -L "$dest" ]; then
    echo "    $dest is already a symlink, skipping"
    return
  fi

  if [ -e "$dest" ]; then
    local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Existing $dest found, backing up to $backup"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"
  echo "    Symlinked $dest -> $src"
}

# ---------------------------------------------------------------------------
# Fish shell
# ---------------------------------------------------------------------------
install_fish() {
  echo "==> Fish"

  local fish_path
  fish_path="$(command -v fish || true)"

  if [ -z "$fish_path" ]; then
    echo "    !! fish not found, skipping"
    return
  fi

  local src="$DOTFILES_DIR/config.fish"
  local config_dir="$HOME/.config/fish"
  local dest="$config_dir/config.fish"

  if [ -f "$src" ]; then
    mkdir -p "$config_dir"

    if [ -L "$dest" ]; then
      echo "    $dest is already a symlink, skipping"
    else
      if [ -e "$dest" ]; then
        local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
        echo "    Existing $dest found, backing up to $backup"
        mv "$dest" "$backup"
      fi

      ln -s "$src" "$dest"
      echo "    Symlinked $dest -> $src"
    fi
  else
    echo "    !! $src not found, skipping config symlink"
  fi

  if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
    echo "    Adding $fish_path to /etc/shells (requires sudo)"
    if ! echo "$fish_path" | sudo tee -a /etc/shells >/dev/null; then
      echo "    !! Failed to update /etc/shells, skipping default shell change"
      echo "    Run manually: echo \"$fish_path\" | sudo tee -a /etc/shells && chsh -s \"$fish_path\""
      return
    fi
  fi

  if [ "$SHELL" = "$fish_path" ]; then
    echo "    fish is already the default shell"
    return
  fi

  echo "    Setting fish as default shell (requires your password)"
  if ! chsh -s "$fish_path"; then
    echo "    !! chsh failed, run manually: chsh -s \"$fish_path\""
  fi
}

# ---------------------------------------------------------------------------
# Add new install_<app> functions below and call them here
# ---------------------------------------------------------------------------

install_karabiner
install_vscode
install_starship
install_ghostty
install_fish
