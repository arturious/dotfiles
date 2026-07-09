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
# Add new install_<group> functions below and call them here
# ---------------------------------------------------------------------------

install_fonts
