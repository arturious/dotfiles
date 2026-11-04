#!/usr/bin/env bash
# Bootstrap a Mac from this checkout: Homebrew, chezmoi, then `chezmoi init --apply`
# with this repo as the source. Same as: chezmoi init --apply --source <this dir>
# (or on a Mac without a checkout: chezmoi init --apply arturious).
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

command -v chezmoi >/dev/null 2>&1 || brew install chezmoi

exec chezmoi init --apply --source "$DOTFILES_DIR"
