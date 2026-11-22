# VS Code / Hermes

Two color themes generated from the same palettes as the Neovim schemes:

- `last-light.json` — Last Light, `vs-dark`
- `first-light.json` — First Light, `vs`

Both include workbench colors, `tokenColors`, and `semanticTokenColors`, with the
sixteen terminal ANSI colors wired to the same values as the Kitty themes.

## Test locally

The folder is a minimal extension (`package.json` + themes). Launch VS Code with
it as a development extension:

```sh
code --extensionDevelopmentPath="$PWD"
```

Then pick **Last Light** or **First Light** from **Preferences: Color Theme** in
the new window.

## Package

```sh
npx @vscode/vsce package --no-dependencies
code --install-extension sundial-theme-0.1.0.vsix
```

## Hermes

Hermes imports themes from the VS Code Marketplace. Until this extension is
published there, use the JSON files in VS Code; once published, Hermes can
install them from **Settings → Appearance → Install theme**.

Regenerate the JSON after palette changes:

```sh
nvim --headless -u NONE -n -i NONE -l scripts/vscode.lua
```
