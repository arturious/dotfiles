# Installed by chezmoi apply (run_onchange_before_install-homebrew-packages.sh.tmpl).

# Fonts
cask "font-jetbrains-mono-nerd-font"

# Apps
cask "karabiner-elements"
cask "hammerspoon"
cask "ghostty"
# Installed outside Homebrew on this Mac and macOS blocks adopting it; skip if present.
cask "cursor" unless File.exist?("/Applications/Cursor.app")
cask "raycast"
cask "zen"
cask "1password"
cask "itsycal"

# CLI
brew "chezmoi"
brew "starship"
brew "fish"
brew "carapace"   # completions for fish (~/.config/fish/config.fish)
brew "tmux"
brew "fzf"
brew "zoxide"
brew "eza"
brew "lazygit"
brew "neovim"
brew "ripgrep"
brew "fd"
brew "gitleaks"     # secret scan, run by pre-commit in this repo
brew "pre-commit"
brew "gh"
brew "node"
cask "1password-cli"
cask "claude-code"
