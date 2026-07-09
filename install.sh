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
# Add new install_<app> functions below and call them here
# ---------------------------------------------------------------------------

install_iterm2
