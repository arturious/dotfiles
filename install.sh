#!/usr/bin/env bash
# One folder per app; this file maps each one to where the app reads it.
# Safe to re-run: existing symlinks are left alone, real files are backed up.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SUPPORT="$HOME/Library/Application Support"

# link <path in dotfiles> <destination>
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
    rm "$dest"                       # stale symlink (e.g. an old dotfiles path)
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
# bash doesn't read fish's PATH, so on a fresh Mac brew isn't found by name.
if ! command -v brew >/dev/null 2>&1; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "    !! Homebrew not installed, see https://brew.sh" >&2
    exit 1
  fi
fi
brew bundle --file "$DOTFILES_DIR/Brewfile"

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------
echo "==> Symlinks"

# Claude Code (theme.json is the "custom:custom" theme)
link claude/settings.json      "$HOME/.claude/settings.json"
link claude/statusline.py      "$HOME/.claude/statusline.py"
link claude/theme.json         "$HOME/.claude/themes/custom.json"

link fish/config.fish          "$HOME/.config/fish/config.fish"
# One file per function, not the whole dir: fisher keeps its own files there.
for fn in "$DOTFILES_DIR"/fish/functions/*.fish; do
  link "fish/functions/${fn##*/}" "$HOME/.config/fish/functions/${fn##*/}"
done
link ghostty/config.ghostty    "$APP_SUPPORT/com.mitchellh.ghostty/config.ghostty"
link hammerspoon               "$HOME/.hammerspoon"
# The whole directory, not just karabiner.json: Karabiner watches
# ~/.config/karabiner, and edits to a symlinked file's target never show up
# there, so the config wouldn't reload on its own.
link karabiner                 "$HOME/.config/karabiner"
link lazygit/config.yml        "$APP_SUPPORT/lazygit/config.yml"
link nvim                      "$HOME/.config/nvim"
link starship/starship.toml    "$HOME/.config/starship.toml"
link inshellisense/rc.toml     "$HOME/.config/inshellisense/rc.toml"
link tmux                      "$HOME/.config/tmux"
link vscode/settings.json      "$APP_SUPPORT/Code/User/settings.json"

link bin/lazygit-claude        "$HOME/.local/bin/lazygit-claude"

# ---------------------------------------------------------------------------
# Special cases
# ---------------------------------------------------------------------------

# tmux: ~/.tmux.conf would win over ~/.config/tmux/tmux.conf, drop the old link.
if [ -L "$HOME/.tmux.conf" ]; then
  rm "$HOME/.tmux.conf"
fi

# TPM (tmux plugin manager) - only used for tmux-claude-hatch.
echo "==> TPM"
tpm_dir="$HOME/.tmux/plugins/tpm"
if [ ! -d "$tpm_dir" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi
"$tpm_dir/bin/install_plugins"

# Zen Browser: the profile folder has a random name, read it from installs.ini.
echo "==> Zen Browser"
zen_dir="$APP_SUPPORT/zen"
profile="$(awk -F= '/^Default=/{print $2; exit}' "$zen_dir/installs.ini" 2>/dev/null || true)"
if [ -z "$profile" ]; then
  echo "    !! Zen profile not found (run Zen once first), skipping"
else
  profile_dir="$zen_dir/$profile"
  link zen/userChrome.css      "$profile_dir/chrome/userChrome.css"
  link zen/user.js             "$profile_dir/user.js"
  link zen/boosts              "$profile_dir/zen-boosts"

  # The boosts index (site -> boost id) is copied, not linked: Zen saves it by
  # replacing the file, which turns a symlink back into a plain file. After
  # adding/renaming boosts, copy it back:
  #   cp "<profile>/zen-boosts.jsonlz4" ~/dotfiles/zen/zen-boosts.jsonlz4
  if [ -f "$DOTFILES_DIR/zen/zen-boosts.jsonlz4" ]; then
    if [ -e "$profile_dir/zen-boosts.jsonlz4" ]; then
      cp "$profile_dir/zen-boosts.jsonlz4" "$profile_dir/zen-boosts.jsonlz4.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cp "$DOTFILES_DIR/zen/zen-boosts.jsonlz4" "$profile_dir/zen-boosts.jsonlz4"
  fi
  echo "    Restart Zen for userChrome.css/user.js/boosts to take effect"
fi

# inshellisense (IDE-style completion while typing, see fish/config.fish).
# Its fish integration joins a multi-line prompt with '\n' in single quotes -
# a literal backslash-n in fish - so the two-line starship prompt showed "\n".
# Patched after every install, since (re)installing rewrites the file.
echo "==> inshellisense"
if command -v npm >/dev/null 2>&1; then
  npm install -g @microsoft/inshellisense >/dev/null
  is_fish="$HOME/.local/share/inshellisense/shell/shellIntegration.fish"
  [ -f "$is_fish" ] || is reinit >/dev/null
  sed -i '' "s/(string join '\\\\n' \$__user_prompt_lines)/(string join \\\\n \$__user_prompt_lines)/" "$is_fish"
fi

# fish as the login shell.
echo "==> fish"
fish_path="$(command -v fish || true)"
if [ -n "$fish_path" ] && [ "$SHELL" != "$fish_path" ]; then
  grep -qxF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$fish_path" || echo "    !! chsh failed, run manually: chsh -s \"$fish_path\""
fi
