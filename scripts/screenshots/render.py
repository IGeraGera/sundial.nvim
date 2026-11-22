#!/usr/bin/env python3
"""Render the README screenshots.

Neovim's ext_linegrid UI protocol hands us the exact screen a terminal would
show, so this needs no pty and no X server: we attach a UI client to an
embedded nvim, rebuild the cell grid, and paint it with Pillow. Colors come
straight from the highlight groups, which is what a theme screenshot wants.

  ./render.py --all
  ./render.py --scheme first-light --mode telescope

Requires python3 with Pillow and msgpack, Neovim, and the JetBrainsMono Nerd
Font (see README.md in this directory).
"""
import argparse
import os
import pathlib
import select
import subprocess
import sys
import time

import msgpack
from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
CACHE = pathlib.Path(os.environ.get("SHOT_CACHE", pathlib.Path.home() / ".cache" / "sundial-screenshots"))
FONT_DIR = os.environ.get("SHOT_FONT_DIR", "/usr/share/fonts/TTF")
FONT_FILE = os.environ.get("SHOT_FONT", "JetBrainsMonoNerdFontMono-%s.ttf")

GRID_COLS = 88
GRID_ROWS = 28
FONT_SIZE = 26
PADDING = 30
CURSOR_LINE = 23


def rgb(value, default=(0, 0, 0)):
    if value is None:
        return default
    return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)


class Nvim:
    """Minimal msgpack-rpc client for `nvim --embed`."""

    def __init__(self, argv, env, cwd):
        self.proc = subprocess.Popen(
            ["nvim", "--embed", "-n", "-i", "NONE", *argv],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            cwd=cwd,
        )
        self.packer = msgpack.Packer(use_bin_type=True)
        self.unpacker = msgpack.Unpacker(raw=False, strict_map_key=False)
        self.msgid = 0
        self.batches = []

    def send(self, obj):
        self.proc.stdin.write(self.packer.pack(obj))
        self.proc.stdin.flush()

    def _read_one(self):
        while True:
            for msg in self.unpacker:
                return msg
            chunk = os.read(self.proc.stdout.fileno(), 1 << 16)
            if not chunk:
                raise EOFError("nvim closed the connection")
            self.unpacker.feed(chunk)

    def request(self, method, *args):
        self.msgid += 1
        mid = self.msgid
        self.send([0, mid, method, list(args)])
        while True:
            msg = self._read_one()
            if msg[0] == 1 and msg[1] == mid:
                if len(msg) > 2 and msg[2] is not None:
                    raise RuntimeError(f"{method}: {msg[2]}")
                return msg[3] if len(msg) > 3 else None
            if msg[0] == 2:
                self.batches.append(msg[2])

    def drain(self, seconds):
        """Collect notifications for a fixed window, returning redraw batches."""
        end = time.time() + seconds
        fd = self.proc.stdout.fileno()
        while True:
            for msg in self.unpacker:
                if msg[0] == 2:
                    self.batches.append(msg[2])
            left = end - time.time()
            if left <= 0:
                break
            ready, _, _ = select.select([fd], [], [], left)
            if not ready:
                continue
            chunk = os.read(fd, 1 << 16)
            if not chunk:
                break
            self.unpacker.feed(chunk)
        batches, self.batches = self.batches, []
        return batches


class Grid:
    def __init__(self, cols, rows):
        self.cols = cols
        self.rows = rows
        self.cells = [[(" ", 0) for _ in range(cols)] for _ in range(rows)]
        self.fg = (0xD2, 0xCA, 0xBB)
        self.bg = (0x0D, 0x10, 0x15)
        self.cursor = (0, 0)
        self.cursor_visible = True

    def clear(self):
        self.cells = [[(" ", 0) for _ in range(self.cols)] for _ in range(self.rows)]

    def resize(self, cols, rows):
        blank = [(" ", 0) for _ in range(cols)]
        self.cells = [(row + blank)[:cols] for row in self.cells][:rows]
        while len(self.cells) < rows:
            self.cells.append(list(blank))
        self.cols, self.rows = cols, rows

    def line(self, row, col, cells):
        if row >= self.rows:
            return
        target = self.cells[row]
        hl = 0
        x = col
        for cell in cells:
            text = cell[0]
            if len(cell) > 1 and cell[1] is not None:
                hl = cell[1]
            # A cell with `repeat` draws the previous character again.
            for _ in range(cell[2] if len(cell) > 2 else 1):
                if x < self.cols:
                    target[x] = (text, hl)
                x += 1

    def scroll(self, top, bot, left, right, count):
        if count > 0:
            for _ in range(count):
                self.cells.insert(bot - 1, self.cells.pop(top))
        elif count < 0:
            for _ in range(-count):
                self.cells.insert(top, self.cells.pop(bot - 1))


class Screen:
    def __init__(self, cols, rows):
        self.grid = Grid(cols, rows)
        self.attrs = {}

    def apply(self, batches):
        for batch in batches:
            for event in batch:
                name, args = event[0], event[1:]
                # Neovim groups each event's positional args into lists.
                if args and all(isinstance(arg, (list, tuple)) for arg in args):
                    for arg in args:
                        self.event(name, list(arg))
                else:
                    self.event(name, list(args))

    def event(self, name, args):
        if name == "default_colors_set":
            self.grid.fg = rgb(args[0], self.grid.fg)
            self.grid.bg = rgb(args[1], self.grid.bg)
        elif name == "hl_attr_define":
            self.attrs[args[0]] = args[1] or {}
        elif name == "grid_resize":
            self.grid.resize(args[1], args[2])
        elif name == "grid_clear":
            self.grid.clear()
        elif name == "grid_line":
            self.grid.line(args[1], args[2], args[3])
        elif name == "grid_scroll":
            self.grid.scroll(args[1], args[2], args[3], args[4], args[5])
        elif name == "grid_cursor_goto":
            self.grid.cursor = (args[1], args[2])
        elif name == "mode_change":
            self.grid.cursor_visible = args[0] not in (
                "cmdline_normal",
                "cmdline_insert",
                "cmdline_replace",
                "more",
                "confirm",
            )


def load_font(size):
    cache = {}

    def get(bold, italic):
        key = (bool(bold), bool(italic))
        if key not in cache:
            name = "Regular"
            if bold and italic:
                name = "BoldItalic"
            elif bold:
                name = "Bold"
            elif italic:
                name = "Italic"
            cache[key] = ImageFont.truetype(os.path.join(FONT_DIR, FONT_FILE % name), size)
        return cache[key]

    return get


def render(screen, out, size, pad, cursor="bar"):
    grid = screen.grid
    font = load_font(size)
    cell_w = round(font(False, False).getlength("M"))
    cell_h = round(size * 1.34)
    img = Image.new(
        "RGB",
        (grid.cols * cell_w + 2 * pad, grid.rows * cell_h + 2 * pad),
        grid.bg,
    )
    draw = ImageDraw.Draw(img)

    def colors(hl):
        attrs = screen.attrs.get(hl) or {}
        fg = rgb(attrs.get("foreground"), grid.fg)
        bg = rgb(attrs.get("background"), grid.bg)
        if attrs.get("reverse"):
            fg, bg = bg, fg
        return fg, bg, attrs

    for row_index, row in enumerate(grid.cells):
        y = pad + row_index * cell_h

        # Paint background runs first so neighbours never clip the text.
        start = 0
        while start < grid.cols:
            fg0, bg0, attrs0 = colors(row[start][1])
            run_bg = fg0 if attrs0.get("reverse") else bg0
            end = start + 1
            while end < grid.cols:
                fg1, bg1, attrs1 = colors(row[end][1])
                if (fg1 if attrs1.get("reverse") else bg1) != run_bg:
                    break
                end += 1
            if run_bg != grid.bg:
                draw.rectangle(
                    [pad + start * cell_w, y, pad + end * cell_w - 1, y + cell_h - 1],
                    fill=run_bg,
                )
            start = end

        for col_index, (text, hl) in enumerate(row):
            if not text or not text.strip():
                continue
            fg, _, attrs = colors(hl)
            x = pad + col_index * cell_w
            face = font(attrs.get("bold"), attrs.get("italic"))
            draw.text((x, y + cell_h / 2), text, font=face, fill=fg, anchor="lm")
            if attrs.get("underline") or attrs.get("undercurl") or attrs.get("underdouble"):
                draw.line([(x, y + cell_h - 3), (x + cell_w - 1, y + cell_h - 3)], fill=fg)
            if attrs.get("strikethrough"):
                draw.line([(x, y + cell_h / 2), (x + cell_w - 1, y + cell_h / 2)], fill=fg)

    if grid.cursor_visible:
        row, col = grid.cursor
        if row < grid.rows and col < grid.cols:
            x = pad + col * cell_w
            y = pad + row * cell_h
            text, hl = grid.cells[row][col]
            fg, bg, attrs = colors(hl)
            if cursor == "bar":
                draw.rectangle([x, y, x + 2, y + cell_h - 1], fill=fg)
            else:
                draw.rectangle([x, y, x + cell_w - 1, y + cell_h - 1], fill=fg)
                if text.strip():
                    face = font(attrs.get("bold"), attrs.get("italic"))
                    draw.text((x, y + cell_h / 2), text, font=face, fill=bg, anchor="lm")

    img.save(out, optimize=True)
    return out


def settle(nvim, screen, step=0.25, quiet=1.2, timeout=8.0):
    """Drain redraws until the screen has been quiet for a while."""
    end = time.time() + timeout
    previous = None
    last_change = time.time()
    while time.time() < end:
        screen.apply(nvim.drain(step))
        snapshot = (
            tuple("".join(cell[0] for cell in row) for row in screen.grid.cells),
            screen.grid.cursor,
        )
        if snapshot != previous:
            previous = snapshot
            last_change = time.time()
        elif time.time() - last_change >= quiet:
            return True
    return False


def capture(scheme, mode, out, cols, rows, size, pad, line, cursor):
    env = dict(os.environ)
    env.update(
        {
            "SHOT_SCHEME": scheme,
            "SHOT_MODE": mode,
            "SHOT_REPO": str(REPO),
            "SHOT_CACHE": str(CACHE),
            "TERM": "xterm-256color",
            "XDG_DATA_HOME": str(CACHE / "xdg" / "data"),
            "XDG_STATE_HOME": str(CACHE / "xdg" / "state"),
            "XDG_CONFIG_HOME": str(CACHE / "xdg" / "config"),
            "XDG_CACHE_HOME": str(CACHE / "xdg" / "cache"),
        }
    )
    for path in ("xdg/data", "xdg/state", "xdg/config", "xdg/cache"):
        (CACHE / path).mkdir(parents=True, exist_ok=True)

    nvim = Nvim(
        ["-u", str(HERE / "init.lua"), "-c", f"normal! {line}G", "sun.lua"],
        env,
        str(HERE),
    )
    screen = Screen(cols, rows)
    try:
        nvim.request("nvim_ui_attach", cols, rows, {"rgb": True, "ext_linegrid": True})
        screen.apply(nvim.drain(0.5))
        settle(nvim, screen)
        if mode == "telescope":
            nvim.request("nvim_input", "gr")
            settle(nvim, screen)
    except EOFError:
        pass
    finally:
        if nvim.proc.poll() is None:
            try:
                nvim.request("nvim_command", "qa!")
            except (EOFError, BrokenPipeError):
                pass
            try:
                nvim.proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                nvim.proc.kill()

    err = nvim.proc.stderr.read().decode(errors="replace").strip()
    if err:
        print(err, file=sys.stderr)
    return render(screen, out, size, pad, cursor)


def default_out(scheme, mode):
    name = f"{scheme}.png" if mode == "hero" else f"{scheme}-telescope.png"
    return REPO / "assets" / "screenshots" / name


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--scheme", default="last-light", choices=["last-light", "first-light"])
    parser.add_argument("--mode", default="hero", choices=["hero", "telescope"])
    parser.add_argument("--out")
    parser.add_argument("--all", action="store_true", help="render all four default images")
    parser.add_argument("--cols", type=int, default=GRID_COLS)
    parser.add_argument("--rows", type=int, default=GRID_ROWS)
    parser.add_argument("--size", type=int, default=FONT_SIZE)
    parser.add_argument("--pad", type=int, default=PADDING)
    parser.add_argument("--line", type=int, default=CURSOR_LINE)
    parser.add_argument("--cursor", default="bar", choices=["bar", "block"])
    args = parser.parse_args()

    if args.out and args.all:
        parser.error("--out cannot be combined with --all")

    site = CACHE / "data" / "nvim" / "site" / "pack" / "demo" / "start"
    missing = [name for name in ("telescope.nvim", "plenary.nvim", "mini.nvim") if not (site / name).is_dir()]
    if missing:
        sys.exit(f"missing {', '.join(missing)} in {site}\nrun {HERE / 'setup.sh'} first")

    jobs = (
        [(scheme, mode) for scheme in ("last-light", "first-light") for mode in ("hero", "telescope")]
        if args.all
        else [(args.scheme, args.mode)]
    )
    for scheme, mode in jobs:
        out = pathlib.Path(args.out) if args.out else default_out(scheme, mode)
        out.parent.mkdir(parents=True, exist_ok=True)
        print(capture(scheme, mode, out, args.cols, args.rows, args.size, args.pad, args.line, args.cursor))


if __name__ == "__main__":
    main()
