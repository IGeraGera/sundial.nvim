# Hermes

Two Hermes skins matching the same palettes as the Neovim schemes:

- `last-light.yaml` — Last Light, dark mode
- `first-light.yaml` — First Light, light mode

## Install

From the root of the `sundial.nvim` checkout, on the machine running the Hermes
backend:

```sh
skins_dir="${HERMES_HOME:-$HOME/.hermes}/skins"
mkdir -p "$skins_dir"
cp -i extras/hermes/first-light.yaml extras/hermes/last-light.yaml "$skins_dir/"
hermes skin list
```

If you use a named Hermes profile, install the files in that profile's `skins/`
directory and run the activation command from that profile.

## Activate

Run one of:

```sh
hermes config set display.skin first-light
hermes config set display.skin last-light
```

In Hermes Desktop, keep the app connected to the backend and activate each skin
once so both appear in **Settings → Appearance**. Pair First Light with **Light**
mode and Last Light with **Dark** mode so the file editor matches.

To return to the default skin:

```sh
hermes config set display.skin default
```
