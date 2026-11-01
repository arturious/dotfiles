#!/bin/bash
# fish as the login shell.
set -euo pipefail

fish_path="$(command -v fish || echo /opt/homebrew/bin/fish)"
if [ -x "$fish_path" ] && [ "$SHELL" != "$fish_path" ]; then
  grep -qxF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$fish_path" || echo "!! chsh failed, run manually: chsh -s \"$fish_path\""
fi
