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

  brew install --cask karabiner-elements
}

# ---------------------------------------------------------------------------
# Formulae
# ---------------------------------------------------------------------------
install_formulae() {
  echo "==> Formulae"

  brew install starship
  brew install fish
  brew install tmux
  brew install fzf
  brew install eza
  brew install lazygit
  brew install neovim
  brew install ripgrep
  brew install fd
}

# ---------------------------------------------------------------------------
# Add new install_<group> functions below and call them here
# ---------------------------------------------------------------------------

install_fonts
install_casks
install_formulae
