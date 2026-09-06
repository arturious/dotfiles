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
# tmux
# ---------------------------------------------------------------------------
install_tmux() {
  echo "==> tmux"

  local src="$DOTFILES_DIR/tmux.conf"
  local dest="$HOME/.tmux.conf"

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
# lazygit
# ---------------------------------------------------------------------------
install_lazygit() {
  echo "==> lazygit"

  local config_src="$DOTFILES_DIR/lazygit-config.yml"
  local config_dir="$HOME/Library/Application Support/lazygit"
  local config_dest="$config_dir/config.yml"

  if [ -f "$config_src" ]; then
    mkdir -p "$config_dir"

    if [ -L "$config_dest" ]; then
      echo "    $config_dest is already a symlink, skipping"
    else
      if [ -e "$config_dest" ]; then
        local config_backup="$config_dest.bak.$(date +%Y%m%d%H%M%S)"
        echo "    Existing $config_dest found, backing up to $config_backup"
        mv "$config_dest" "$config_backup"
      fi

      ln -s "$config_src" "$config_dest"
      echo "    Symlinked $config_dest -> $config_src"
    fi
  else
    echo "    !! $config_src not found, skipping config symlink"
  fi

  local script_src="$DOTFILES_DIR/lazygit-ai-commit-msg"
  local bin_dir="$HOME/.local/bin"
  local script_dest="$bin_dir/lazygit-ai-commit-msg"

  if [ -f "$script_src" ]; then
    mkdir -p "$bin_dir"

    if [ -L "$script_dest" ]; then
      echo "    $script_dest is already a symlink, skipping"
    else
      if [ -e "$script_dest" ]; then
        local script_backup="$script_dest.bak.$(date +%Y%m%d%H%M%S)"
        echo "    Existing $script_dest found, backing up to $script_backup"
        mv "$script_dest" "$script_backup"
      fi

      ln -s "$script_src" "$script_dest"
      echo "    Symlinked $script_dest -> $script_src"
    fi
  else
    echo "    !! $script_src not found, skipping script symlink"
  fi
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

  local functions_dir="$config_dir/functions"
  mkdir -p "$functions_dir"
  for fn in "$DOTFILES_DIR"/functions/*.fish; do
    [ -f "$fn" ] || continue
    local fn_dest="$functions_dir/$(basename "$fn")"
    if [ -L "$fn_dest" ]; then
      echo "    $fn_dest is already a symlink, skipping"
    else
      if [ -e "$fn_dest" ]; then
        local fn_backup="$fn_dest.bak.$(date +%Y%m%d%H%M%S)"
        echo "    Existing $fn_dest found, backing up to $fn_backup"
        mv "$fn_dest" "$fn_backup"
      fi
      ln -s "$fn" "$fn_dest"
      echo "    Symlinked $fn_dest -> $fn"
    fi
  done

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
# Zen Browser
# ---------------------------------------------------------------------------
install_zen() {
  echo "==> Zen Browser"

  local zen_dir="$HOME/Library/Application Support/zen"
  local installs_ini="$zen_dir/installs.ini"

  if [ ! -f "$installs_ini" ]; then
    echo "    !! $installs_ini not found (run Zen once first), skipping"
    return
  fi

  local rel_path
  rel_path="$(awk -F= '/^Default=/{print $2; exit}' "$installs_ini")"

  if [ -z "$rel_path" ]; then
    echo "    !! Could not determine default Zen profile, skipping"
    return
  fi

  local profile_dir="$zen_dir/$rel_path"
  local chrome_dir="$profile_dir/chrome"
  local src="$DOTFILES_DIR/userChrome.css"
  local dest="$chrome_dir/userChrome.css"

  if [ ! -f "$src" ]; then
    echo "    !! $src not found, skipping"
    return
  fi

  mkdir -p "$chrome_dir"

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

  local user_js_src="$DOTFILES_DIR/user.js"
  local user_js_dest="$profile_dir/user.js"

  if [ -f "$user_js_src" ]; then
    if [ -L "$user_js_dest" ]; then
      echo "    $user_js_dest is already a symlink, skipping"
    else
      if [ -e "$user_js_dest" ]; then
        local user_js_backup="$user_js_dest.bak.$(date +%Y%m%d%H%M%S)"
        echo "    Existing $user_js_dest found, backing up to $user_js_backup"
        mv "$user_js_dest" "$user_js_backup"
      fi

      ln -s "$user_js_src" "$user_js_dest"
      echo "    Symlinked $user_js_dest -> $user_js_src"
    fi
  else
    echo "    !! $user_js_src not found, skipping user.js symlink"
  fi

  echo "    Restart Zen for userChrome.css/user.js to take effect"
}

# ---------------------------------------------------------------------------
# Add new install_<app> functions below and call them here
# ---------------------------------------------------------------------------

install_karabiner
install_vscode
install_starship
install_tmux
install_ghostty
install_lazygit
install_zen
install_fish
