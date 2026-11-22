# Screenshots

Generates `assets/screenshots/`, the images in the top-level README.

```sh
./setup.sh                 # clone telescope, plenary, mini into ~/.cache/sundial-screenshots
./render.py --all          # rewrite all four images
./verify.py                # palette, layout, README and reproducibility checks
```

`--all` renders both schemes in both modes. To iterate on a single image:

```sh
./render.py --scheme first-light --mode telescope
./render.py --scheme last-light --mode hero --out /tmp/try.png --size 30
```

## Why a UI client instead of a terminal screenshot

There is no terminal and no display server involved. `render.py` starts
`nvim --embed`, attaches a UI with `ext_linegrid`, and rebuilds the cell grid
from the redraw events (`grid_line`, `hl_attr_define`, `grid_cursor_goto`,
`grid_scroll`, …). That is the same data a TUI receives, so the result is
Neovim's own screen: buffer, cursorline, statusline, Telescope float and
cursor, with colors taken from the highlight groups.

Painting that grid with [Pillow](https://python-pillow.org) avoids the two
things a real capture needs and this environment cannot provide — a pty and an
X connection — and it makes the output reproducible: re-rendering an unchanged
tree produces byte-identical PNGs. `verify.py` relies on that.

## Requirements

- Python 3 with `Pillow` and `msgpack`.
- Neovim (tested on 0.13; `--embed` and `ext_linegrid` are older than that).
- JetBrainsMono Nerd Font (Mono variant, regular/bold/italic/bold-italic).
- The three plugins from `setup.sh`, used only for the statusline and picker.

Override the cache, font, or font directory with `SHOT_CACHE`, `SHOT_FONT`,
and `SHOT_FONT_DIR`.

## What is drawn

`sun.lua` is the demo buffer, opened at line 23 on an 88×28 grid with 26 px
JetBrainsMono NFM. `init.lua` loads the theme straight from this checkout,
enables `mini.statusline`, and — in `telescope` mode — `:badd`s a fixed list of
theme modules and opens the buffer picker as a bottom pane at 30 % height, so
the buffer above stays readable.

The list is fixed on purpose: a filesystem-backed picker (`find_files`,
`git_files`) changes its counter and its tie order whenever files are added,
which would make the images drift. `gr` is typed into the prompt by the
harness and the capture waits until the screen has been quiet for 1.2 s.

## What is not drawn

No font shaping and no ligatures: Pillow draws one cell at a time, so the cell
width is taken from the font's `M`. The cursor, padding, and image borders are
ours; everything inside the grid is Neovim's. There is no window chrome, which
is what the README wants.
