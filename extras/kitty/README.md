# Kitty

Two Kitty themes generated from the same palettes as the Neovim schemes:

- `last-light.conf` — warm ivory and amber on a near-black background
- `first-light.conf` — warm paper with daylight inks

Copy or symlink one into your Kitty config directory and include it from
`kitty.conf`:

```conf
include first-light.conf
```

Reload Kitty with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F5</kbd>, or try a theme
without touching your config:

```sh
kitty -o include=/path/to/first-light.conf
```

Regenerate both files after palette changes:

```sh
nvim --headless -u NONE -n -i NONE -l scripts/kitty.lua
```
