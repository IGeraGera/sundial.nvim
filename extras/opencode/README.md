# OpenCode

Two OpenCode TUI themes generated from the same palettes as the Neovim
schemes:

- `last-light.json` — Last Light, dark mode
- `first-light.json` — First Light, light mode

Each file provides one mode, so OpenCode uses it whenever a mode is requested.
The syntax, Markdown, and diff colors follow the Neovim highlight groups.

## Install

Copy the JSON files into the global themes directory:

```sh
mkdir -p ~/.config/opencode/themes
cp last-light.json first-light.json ~/.config/opencode/themes/
```

For a single project, put them in `.opencode/themes` instead. Restart OpenCode,
then run `/themes` and choose **last-light** or **first-light**. The filename
becomes the theme name.

You can also select a theme in `~/.config/opencode/cli.json`:

```json
{
  "$schema": "https://opencode.ai/v2/cli.json",
  "theme": {
    "name": "last-light",
    "mode": "dark"
  }
}
```

Regenerate both files after palette changes:

```sh
nvim --headless -u NONE -n -i NONE -l scripts/opencode.lua
```
