"""Renders the DiveDown app icon (variant D "Brille mit Clownfisch",
chosen 2026-11-23, ui-spec §1, T29) into the PNG sizes for iOS and the
legacy Android mipmaps.

The shapes below are in the 160 x 160 grid of the SVG masters in
assets/icon/ (same path strings). They are drawn with Pillow at 4x
supersampling, because no SVG renderer is needed on the build PC.
Android 8+ uses the vector layers in res/drawable instead.

    python tool/render_app_icons.py              # write all icons
    python tool/render_app_icons.py --preview X  # one preview sheet to X

GPL-3.0-or-later.
"""

import json
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SURFACE = (0xF2, 0xF8, 0xF8)
PRIMARY = (0x0B, 0x7A, 0x80)
NAVY = (0x13, 0x30, 0x3A)
STREAK = (0x22, 0x96, 0x9B)  # primaryLight #4CC9CE at 35 % over the lens
ORANGE = (0xF2, 0x6B, 0x1D)
WHITE = (0xFF, 0xFF, 0xFF)

FRAME = ("M34 70 Q34 58 48 58 H112 Q126 58 126 70 V96 Q126 116 108 116 H96 "
         "Q88 116 84 106 Q80 100 76 106 Q72 116 64 116 H52 Q34 116 34 96 Z")
LENS = ("M42 72 Q42 66 50 66 H110 Q118 66 118 72 V94 Q118 108 106 108 H98 "
        "Q92 108 88 100 Q80 90 72 100 Q68 108 62 108 H54 Q42 108 42 94 Z")
STREAK_LINE = "M54 100 L102 70"
HIGHLIGHT = "M48 78 Q49 71 55 70"
TAIL = "M69 81 L57 72 L60 81 L57 90 Z"
BODY = "M101 83 Q88 67 68 80 Q88 97 101 83 Z"
STRIPES = [(75, 66, 5, 32), (88, 66, 4.5, 32)]
STRAPS = [(12, 80, 24, 12), (124, 80, 24, 12)]
EYE = (96, 81, 2)
BUBBLES = [(100, 44, 6, 3), (112, 30, 4, 2.5), (98, 22, 3, 2)]
OUTLINE = 1.2


def _flatten(d, steps=24):
    """Points of an absolute M/L/H/V/Q/Z path."""
    tokens = re.findall(r"[MLHVQZ]|-?\d+(?:\.\d+)?", d)
    pts, i, cmd = [], 0, None
    x = y = 0.0
    while i < len(tokens):
        if tokens[i].isalpha():
            cmd = tokens[i]
            i += 1
            if cmd == "Z":
                pts.append(pts[0])
                continue
        n = lambda k: float(tokens[i + k])  # noqa: E731
        if cmd in "ML":
            x, y = n(0), n(1)
            pts.append((x, y))
            i += 2
        elif cmd == "H":
            x = n(0)
            pts.append((x, y))
            i += 1
        elif cmd == "V":
            y = n(0)
            pts.append((x, y))
            i += 1
        elif cmd == "Q":
            cx, cy, ex, ey = n(0), n(1), n(2), n(3)
            for s in range(1, steps + 1):
                t = s / steps
                u = 1 - t
                pts.append((u * u * x + 2 * u * t * cx + t * t * ex,
                            u * u * y + 2 * u * t * cy + t * t * ey))
            x, y = ex, ey
            i += 4
    return pts


def _stroke(draw, points, width, fill):
    # A row of round dabs: round caps and joins without gaps.
    r = width / 2
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        n = max(1, int(((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5 / (r / 3)))
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / n
            y = y0 + (y1 - y0) * i / n
            draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def _ring(draw, cx, cy, r, width, k, fill):
    draw.ellipse(((cx - r - width / 2) * k, (cy - r - width / 2) * k,
                  (cx + r + width / 2) * k, (cy + r + width / 2) * k), fill=fill)
    draw.ellipse(((cx - r + width / 2) * k, (cy - r + width / 2) * k,
                  (cx + r - width / 2) * k, (cy + r - width / 2) * k), fill=SURFACE)


def render(size, small=False):
    """RGB image of the icon at size x size pixels; [small] drops the fine
    details (outlines, highlight, smallest bubbles) for sizes below 60 px."""
    ss = 4
    big = size * ss
    k = big / 160
    sc = lambda pts: [(x * k, y * k) for x, y in pts]  # noqa: E731
    img = Image.new("RGB", (big, big), SURFACE)
    draw = ImageDraw.Draw(img)

    for x, y, w, h in STRAPS:
        draw.rounded_rectangle((x * k, y * k, (x + w) * k, (y + h) * k), 3 * k, fill=PRIMARY)
    draw.polygon(sc(_flatten(FRAME)), fill=NAVY)
    draw.polygon(sc(_flatten(LENS)), fill=PRIMARY)
    if not small:
        _stroke(draw, sc(_flatten(STREAK_LINE)), 10 * k, STREAK)
        _stroke(draw, sc(_flatten(HIGHLIGHT)), 3 * k, WHITE)

    tail = sc(_flatten(TAIL))
    body = sc(_flatten(BODY))
    draw.polygon(tail, fill=ORANGE)
    if not small:
        _stroke(draw, tail, OUTLINE * k, NAVY)
    draw.polygon(body, fill=ORANGE)

    stripes = Image.new("RGB", (big, big), ORANGE)
    sd = ImageDraw.Draw(stripes)
    o = 0 if small else OUTLINE / 2
    for x, y, w, h in STRIPES:
        if not small:
            sd.rectangle(((x - o) * k, (y - o) * k, (x + w + o) * k, (y + h + o) * k), fill=NAVY)
        sd.rectangle(((x + o) * k, (y + o) * k, (x + w - o) * k, (y + h - o) * k), fill=WHITE)
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).polygon(body, fill=255)
    img.paste(stripes, (0, 0), mask)
    draw = ImageDraw.Draw(img)
    if not small:
        _stroke(draw, body, OUTLINE * k, NAVY)
    ex, ey, er = EYE
    draw.ellipse(((ex - er) * k, (ey - er) * k, (ex + er) * k, (ey + er) * k), fill=NAVY)

    if not small:
        cx, cy, r = 106, 76, 2
        draw.ellipse(((cx - r - .75) * k, (cy - r - .75) * k, (cx + r + .75) * k, (cy + r + .75) * k), fill=WHITE)
        draw.ellipse(((cx - r + .75) * k, (cy - r + .75) * k, (cx + r - .75) * k, (cy + r - .75) * k), fill=PRIMARY)
    bubbles = BUBBLES if not small else [(100, 44, 6, 4), (112, 30, 4, 3.5)]
    for cx, cy, r, w in bubbles:
        _ring(draw, cx, cy, r, w, k, PRIMARY)
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
    sizes = [180, 120, 58, 40]
    sheet = Image.new("RGB", (1024 + 40 + 180 + 40, 1064), (255, 255, 255))
    sheet.paste(render(1024), (20, 20))
    y = 20
    for s in sizes:
        sheet.paste(render(s, small=s < 60), (1064, y))
        y += s + 30
    sheet.save(path)


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--preview":
        preview(sys.argv[2])
    else:
        write_all(Path(__file__).resolve().parent.parent)
