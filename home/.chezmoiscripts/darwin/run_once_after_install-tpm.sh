#!/bin/bash
# tmux plugin manager and the plugins from tmux.conf.
set -euo pipefail

tpm_dir="$HOME/.tmux/plugins/tpm"
if [ ! -d "$tpm_dir" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi
"$tpm_dir/bin/install_plugins"
