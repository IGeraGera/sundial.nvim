#!/usr/bin/env python3
"""Verify the README screenshots against the palette and the README itself."""
import pathlib
import re
import sys
from collections import Counter

from PIL import Image

repo = pathlib.Path(__file__).resolve().parent.parent.parent
shots = repo / "assets" / "screenshots"
failures = []


def check(condition, message):
    print(("  ok   " if condition else "  FAIL ") + message)
    if not condition:
        failures.append(message)


def hex_to_rgb(value):
    return tuple(int(value.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(value):
    return "#%02X%02X%02X" % value


def palette(name):
    text = (repo / "lua" / "sundial" / "colors" / f"{name}.lua").read_text()
    return {
        key: "#" + value.lstrip("#").upper()
        for key, value in re.findall(r'(\w+)\s*=\s*"(#?[0-9A-Fa-f]{6})"', text)
    }


def mix(base, tint, strength):
    a, b = hex_to_rgb(base), hex_to_rgb(tint)
    return rgb_to_hex(tuple(int(x + (y - x) * strength + 0.5) for x, y in zip(a, b)))


def derived(pal, variant):
    """Colors the theme builds by mixing, plus terminal ANSI mixes."""
    return {
        "selection": mix(pal["bg_panel"], pal["slate"], 0.24),
        "prompt": mix(pal["bg"], pal["bg_panel"], 0.55) if variant == "last" else pal["bg_line"],
    }


def is_blend(color, allowed, tol=2.0):
    """True when the color sits on the line between two allowed colors."""
    for a in allowed:
        for b in allowed:
            if a == b:
                continue
            if any(
                min(a[i], b[i]) - tol > color[i] or color[i] > max(a[i], b[i]) + tol
                for i in range(3)
            ):
                continue
            ratios = [(color[i] - a[i]) / (b[i] - a[i]) for i in range(3) if b[i] != a[i]]
            if not ratios:
                continue
            mean = sum(ratios) / len(ratios)
            if -0.03 <= mean <= 1.03 and all(abs(r - mean) <= 0.03 for r in ratios):
                return True
    return False


def load(name):
    path = shots / name
    with Image.open(path) as img:
        img.load()
        return img.copy(), img.format


schemes = {"last-light": ("last", palette("last")), "first-light": ("first", palette("first"))}
core = ["bg", "bg_panel", "fg", "comment", "rose", "green", "amber", "lavender", "blue"]
already_seen = set()

images = {}
for scheme, (variant, pal) in schemes.items():
    extras = derived(pal, variant)
    allowed = [hex_to_rgb(v) for v in pal.values()] + [hex_to_rgb(v) for v in extras.values()]
    for mode in ("hero", "telescope"):
        name = f"{scheme}.png" if mode == "hero" else f"{scheme}-telescope.png"
        print(f"\n{name}")
        img, fmt = load(name)
        images[(scheme, mode)] = img
        check(fmt == "PNG", "PNG container")
        check(img.mode == "RGB", f"no alpha channel (mode {img.mode})")
        check(img.size == (1468, 1040), f"size {img.size}")
        counts = Counter(img.getdata())
        bg = pal["bg"]
        check(rgb_to_hex(img.getpixel((0, 0))) == bg, f"corner is palette bg {bg}")

        keys = core + (["bg_line"] if mode == "hero" else [])
        for key in keys:
            check(counts[hex_to_rgb(pal[key])] > 0, f"palette {key} {pal[key]} present ({counts[hex_to_rgb(pal[key])]} px)")
        if mode == "telescope":
            for key, value in extras.items():
                check(
                    counts[hex_to_rgb(value)] > 0,
                    f"derived {key} {value} present ({counts[hex_to_rgb(value)]} px)",
                )

        unknown = [
            (color, n)
            for color, n in counts.most_common(30)
            if color not in allowed and n >= 50 and not is_blend(color, allowed)
        ]
        check(not unknown, f"every color is palette or a blend ({[(rgb_to_hex(c), n) for c, n in unknown]})")

        bg_rgb = hex_to_rgb(bg)
        pixels = img.load()
        cols = [x for x in range(img.width) if any(pixels[x, y] != bg_rgb for y in range(0, img.height, 4))]
        rows = [y for y in range(img.height) if any(pixels[x, y] != bg_rgb for x in range(0, img.width, 4))]
        left, right, top, bottom = min(cols), max(cols), min(rows), max(rows)
        check(left >= 20 and img.width - right >= 20, f"horizontal padding {left}/{img.width - right}px")
        check(top >= 20 and img.height - bottom >= 20, f"vertical padding {top}/{img.height - bottom}px")
        check(counts[bg_rgb] > img.width * img.height * 0.5, "background dominates the frame")

        band = Counter(img.crop((0, bottom - 30, img.width, bottom + 1)).getdata())
        check(band[hex_to_rgb(pal["bg_panel"])] > 1000, "statusline strip uses bg_panel")

        mode_color = "blue" if mode == "hero" else "green"
        check(counts[hex_to_rgb(pal[mode_color])] > 200, f"{mode_color} mode pill present")

        key = (name, tuple(sorted(counts.items())))
        check(key not in already_seen, "identical to another image")
        already_seen.add(key)

for scheme in schemes:
    hero, tele = images[(scheme, "hero")], images[(scheme, "telescope")]
    print(f"\n{scheme}: hero vs telescope")
    first_diff = next(
        (
            y
            for y in range(hero.height)
            if hero.crop((0, y, hero.width, y + 1)).tobytes()
            != tele.crop((0, y, tele.width, y + 1)).tobytes()
        ),
        None,
    )
    check(first_diff is not None and first_diff > 550, f"buffer above the picker is unchanged (row {first_diff})")

print("\nlast-light vs first-light")
a, b = images[("last-light", "hero")], images[("first-light", "hero")]
check(a.tobytes() != b.tobytes(), "schemes produce different images")
check(a.getpixel((0, 0)) != b.getpixel((0, 0)), "different backgrounds")


def content_mask(img, bg):
    bg_rgb = hex_to_rgb(bg)
    return [pixel != bg_rgb for pixel in img.get_flattened_data()]


for mode in ("hero", "telescope"):
    masks = [
        content_mask(images[(scheme, mode)], palette(variant)["bg"])
        for scheme, (variant, _) in schemes.items()
    ]
    same = sum(1 for x, y in zip(*masks) if x == y) / len(masks[0])
    check(same > 0.995, f"{mode}: identical layout across schemes ({same:.2%} of pixels)")

print("\nREADME")
readme = (repo / "README.md").read_text()
linked = re.findall(r"\]\((assets/screenshots/[^)]+)\)", readme)
for rel in linked:
    check((repo / rel).is_file(), f"link target exists: {rel}")
check(
    sorted(pathlib.Path(p).name for p in linked) == sorted(p.name for p in shots.glob("*.png")),
    "all images referenced",
)
check(readme.index("## Screenshots") < readme.index("## Installation"), "section sits before Installation")

print("\n" + ("FAILURES: " + ", ".join(failures) if failures else "all checks passed"))
sys.exit(1 if failures else 0)
