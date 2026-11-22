#!/usr/bin/env bash
# Fetch the plugins the screenshot harness needs into $SHOT_CACHE.
# Nothing is installed into the user's Neovim config.
set -euo pipefail

cache=${SHOT_CACHE:-$HOME/.cache/sundial-screenshots}
start=$cache/data/nvim/site/pack/demo/start
mkdir -p "$start"

for repo in nvim-lua/plenary.nvim nvim-telescope/telescope.nvim echasnovski/mini.nvim; do
  name=${repo##*/}
  if [ -d "$start/$name" ]; then
    echo "have   $name"
  else
    echo "clone  $name"
    git clone --depth 1 "https://github.com/$repo.git" "$start/$name"
  fi
done
