"""Renders the DiveDown app icon (variant A "Tiefenkurve", Riff colours,
ui-spec §1) into the PNG sizes for iOS and the legacy Android mipmaps.

The SVG files in assets/icon/ are the masters; this script draws the same
shapes with Pillow (4x supersampling), because no SVG renderer is needed on
the build PC. Android 8+ uses the vector layers in res/drawable instead.

    python tool/render_app_icons.py              # write all icons
    python tool/render_app_icons.py --preview X  # one preview sheet to X

GPL-3.0-or-later.
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SURFACE = (0xF2, 0xF8, 0xF8)
PRIMARY = (0x0B, 0x7A, 0x80)
ACCENT = (0xB9, 0x41, 0x2A)

# The curve of divedown_icon.svg in its 1024 grid, "S" segments expanded.
SEGMENTS = [
    ((170, 330), (270, 330), (300, 730), (430, 750)),
    ((430, 750), (560, 770), (650, 720), (720, 590)),
    ((720, 590), (790, 460), (800, 330), (860, 330)),
]
WATERLINE_Y = 330


def _curve_points(steps=60):
    points = []
    for p0, p1, p2, p3 in SEGMENTS:
        for i in range(steps + 1):
            t = i / steps
            u = 1 - t
            x = u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0]
            y = u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]
            points.append((x, y))
    return points


def _polyline(draw, points, width, fill):
    # A row of round dabs: round caps and joins without the gaps that
    # ImageDraw.line leaves in thick curves.
    r = width / 2
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        n = max(1, int(((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5 / (r / 4)))
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / n
            y = y0 + (y1 - y0) * i / n
            draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def render(size, small=False):
    """RGB image of the icon at size x size pixels."""
    ss = 4
    big = size * ss
    k = big / 1024
    img = Image.new("RGB", (big, big), SURFACE)
    pts = [(x * k, y * k) for x, y in _curve_points()]

    if not small:
        # Area under the curve: primary fading in towards the depth.
        layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        mask = Image.new("L", (big, big), 0)
        ImageDraw.Draw(mask).polygon(pts, fill=255)
        top, bottom = WATERLINE_Y * k, 770 * k
        gradient = Image.new("L", (1, big), 0)
        for y in range(big):
            f = min(1, max(0, (y - top) / (bottom - top)))
            gradient.putpixel((0, y), int(255 * (0.05 + 0.37 * f)))
        alpha = gradient.resize((big, big))
        alpha = Image.composite(alpha, Image.new("L", (big, big), 0), mask)
        layer.paste(PRIMARY + (255,), (0, 0, big, big))
        layer.putalpha(alpha)
        img.paste(layer, (0, 0), layer)
        # Waterline, light.
        line = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        ImageDraw.Draw(line).line(
            [(150 * k, WATERLINE_Y * k), (874 * k, WATERLINE_Y * k)],
            fill=PRIMARY + (70,),
            width=int(20 * k),
        )
        img.paste(line, (0, 0), line)

    draw = ImageDraw.Draw(img)
    _polyline(draw, pts, (70 if small else 60) * k, PRIMARY)
    bubbles = [(770, 230, 36)] if small else [(770, 230, 30), (830, 160, 18)]
    for cx, cy, r in bubbles:
        draw.ellipse(((cx - r) * k, (cy - r) * k, (cx + r) * k, (cy + r) * k), fill=ACCENT)
    return img.resize((size, size), Image.LANCZOS)


def write_all(root):
    ios = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios / "Contents.json").read_text(encoding="utf-8"))
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        px = round(points * scale)
        render(px, small=px < 60).save(ios / image["filename"])
    res = root / "android/app/src/main/res"
    for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        render(px, small=px < 60).save(res / f"mipmap-{density}" / "ic_launcher.png")


def preview(path):
    sizes = [1024, 180, 120, 58, 40]
    sheet = Image.new("RGB", (1024 + 40 + 180 + 40 + 120 + 40, 1064), (255, 255, 255))
    sheet.paste(render(1024), (20, 20))
    x = 1064
    y = 20
    for s in sizes[1:]:
        sheet.paste(render(s, small=s < 60), (x, y))
        y += s + 30
    sheet.save(path)


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--preview":
        preview(sys.argv[2])
    else:
        write_all(Path(__file__).resolve().parent.parent)
