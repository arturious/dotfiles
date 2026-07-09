#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------
install_fonts() {
  echo "==> Fonts"

  brew install --cask font-jetbrains-mono-nerd-font
}

# ---------------------------------------------------------------------------
# Casks
# ---------------------------------------------------------------------------
install_casks() {
  echo "==> Casks"

  brew install --cask iterm2
  brew install --cask karabiner-elements
}

# ---------------------------------------------------------------------------
# Add new install_<group> functions below and call them here
# ---------------------------------------------------------------------------

install_fonts
install_casks
