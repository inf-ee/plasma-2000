#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
"""Generates the Windows 2000 style Plymouth images (and a preview) for this theme.

Everything is laid out on a 640x480 "screen", like the original, and rendered at
K times that size so Plymouth can scale it down to the real resolution.

No distribution logo, version or icon is baked in: the installer copies the
system's logo and the SE98C password icon next to these images, and the boot
script places them (logo centred at LOGO_CENTRE in art.png, LOGO_SIZE wide).
The distribution name comes from one of the prebuilt wordmarks/<key>.png.

Run:  python3 -I tools/build.py [--preview]   (needs Pillow; only for development)
"""
import os
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)
K = 4

# Liberation Sans lives in a different folder on each distribution
LIBERATION_DIRS = ["/usr/share/fonts/truetype/liberation",      # Debian, Ubuntu
                   "/usr/share/fonts/liberation-sans-fonts",    # Fedora 40+
                   "/usr/share/fonts/liberation-sans",          # older Fedora
                   "/usr/share/fonts/liberation",               # Arch
                   "/usr/share/fonts/truetype"]                 # openSUSE
TAHOMA = os.path.join(HERE, "tahoma.ttf")
TAHOMA_BOLD = os.path.join(HERE, "tahomabd.ttf")

# boot screen title per distribution (key = lib/branding.sh P2K_WORDMARK)
WORDMARKS = {
    "generic": "KDE Plasma",
    "kubuntu": "Kubuntu",
    "neon": "KDE neon",
    "debian": "Debian",
    "fedora": "Fedora",
    "arch": "Arch Linux",
    "opensuse": "openSUSE",
}
TAGLINE = "Built on Linux Technology"
# where the boot script puts the logo inside art.png (640x290 virtual px)
LOGO_CENTRE = (261, 129)
LOGO_SIZE = 112

FACE = (212, 208, 200)
WHITE = (255, 255, 255)
SHADOW = (128, 128, 128)
DARK = (64, 64, 64)
BLACK = (0, 0, 0)
NAVY = (10, 36, 106)
TITLE_END = (166, 202, 240)
STRIPE = [(0.0, (1, 55, 85)), (0.25, (96, 168, 217)), (0.5, (158, 192, 218)),
          (0.75, (96, 168, 217)), (1.0, (1, 55, 85))]


def lib(name):
    """Path of a Liberation Sans file, e.g. lib("LiberationSans-Bold.ttf")."""
    for d in LIBERATION_DIRS:
        p = os.path.join(d, name)
        if os.path.exists(p):
            return p
    try:
        style = name[len("LiberationSans-"):-len(".ttf")].replace("BoldItalic", "Bold Italic")
        p = subprocess.run(["fc-match", "-f", "%{file}", "Liberation Sans:style=" + style],
                           capture_output=True, text=True).stdout.strip()
        if os.path.basename(p) == name:
            return p
    except OSError:
        pass
    sys.exit(f"{name} not found: install the Liberation fonts "
             "(fonts-liberation, liberation-sans-fonts or ttf-liberation)")


def font(path, px):
    return ImageFont.truetype(path, int(px * K))


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def gradient_at(stops, t):
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        if p0 <= t <= p1:
            return lerp(c0, c1, (t - p0) / (p1 - p0) if p1 > p0 else 0)
    return stops[-1][1]


def hgradient(img, x, y, w, h, stops):
    d = ImageDraw.Draw(img)
    for i in range(w):
        d.line([(x + i, y), (x + i, y + h - 1)], fill=gradient_at(stops, i / max(1, w - 1)))


def rect(d, x, y, w, h, color):
    """Rectangle in 1x units."""
    d.rectangle([x * K, y * K, (x + w) * K - 1, (y + h) * K - 1], fill=color)


def bevel(d, x, y, w, h, tl1, br1, tl2, br2):
    """Two-pixel classic bevel in 1x units (outer tl/br, inner tl/br)."""
    rect(d, x, y, w, 1, tl1); rect(d, x, y, 1, h, tl1)
    rect(d, x, y + h - 1, w, 1, br1); rect(d, x + w - 1, y, 1, h, br1)
    rect(d, x + 1, y + 1, w - 2, 1, tl2); rect(d, x + 1, y + 1, 1, h - 2, tl2)
    rect(d, x + 1, y + h - 2, w - 2, 1, br2); rect(d, x + w - 2, y + 1, 1, h - 2, br2)


def text(d, x, y, s, f, fill=BLACK, spacing=0.0):
    """Draws text at 1x position; spacing is extra letter spacing in 1x px."""
    if not spacing:
        d.text((x * K, y * K), s, font=f, fill=fill)
        return
    cx = x * K
    for ch in s:
        d.text((cx, y * K), ch, font=f, fill=fill)
        cx += f.getlength(ch) + spacing * K


def text_width(s, f, spacing=0.0):
    return (sum(f.getlength(ch) for ch in s) + spacing * K * len(s)) / K if spacing else f.getlength(s) / K


def save(img, name):
    img.save(os.path.join(OUT, name))
    return img


# ---------- password dialog ----------
def password_dialog(lines):
    W, H = 340, 150
    img = Image.new("RGBA", (W * K, H * K), FACE + (255,))
    d = ImageDraw.Draw(img)
    bevel(d, 0, 0, W, H, FACE, DARK, WHITE, SHADOW)
    title = Image.new("RGB", ((W - 6) * K, 18 * K))
    hgradient(title, 0, 0, title.width, title.height, [(0, NAVY), (1, TITLE_END)])
    img.paste(title, (3 * K, 3 * K))
    text(d, 6, 5, "Enter Password", font(TAHOMA_BOLD, 11), fill=WHITE)

    # the 32px password icon goes at (14, 34); the boot script draws it (icon-password.png)

    f = font(TAHOMA, 11)
    for i, line in enumerate(lines):
        text(d, 60, 34 + i * 16, line, f)

    field = (130, 82, 196, 20)  # x, y, w, h
    text(d, 60, 86, "Password:", f)
    rect(d, field[0], field[1], field[2], field[3], WHITE)
    bevel(d, *field, SHADOW, WHITE, DARK, FACE)

    # cosmetic default OK button
    bx, by, bw, bh = W - 10 - 75, H - 10 - 23, 75, 23
    rect(d, bx, by, bw, bh, BLACK)
    rect(d, bx + 1, by + 1, bw - 2, bh - 2, FACE)
    bevel(d, bx + 1, by + 1, bw - 2, bh - 2, WHITE, DARK, FACE, SHADOW)
    ok_w = text_width("OK", f)
    text(d, bx + (bw - ok_w) / 2, by + 5, "OK", f)
    return img, field


def asterisk():
    f = font(lib("LiberationSans-Bold.ttf"), 14)
    img = Image.new("RGBA", (8 * K, 20 * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w = f.getlength("*")
    d.text(((8 * K - w) / 2, 3 * K), "*", font=f, fill=BLACK)
    return img


def label(s, px=11, bold=False, color=BLACK):
    f = font(TAHOMA_BOLD if bold else TAHOMA, px)
    w = int(text_width(s, f)) + 2
    img = Image.new("RGBA", (w * K, (px + 6) * K), (0, 0, 0, 0))
    text(ImageDraw.Draw(img), 0, 1, s, f, fill=color)
    return img


# ---------- Win2000 boot screen pieces ----------
def square(img, box, frame, inner, ring=0, blur=0):
    """Framed square: outer gradient `frame` (top->bottom), inner gradient `inner`."""
    from PIL import ImageFilter
    x0, y0, x1, y1 = box
    w, h = (x1 - x0) * K, (y1 - y0) * K
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sq = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(sq)
    for yy in range(h):
        d.line([(0, yy), (w, yy)], fill=lerp(frame[0], frame[1], yy / max(1, h - 1)))
    if ring:
        r = ring * K
        for yy in range(r, h - r):
            d.line([(r, yy), (w - r - 1, yy)], fill=lerp(inner[0], inner[1], (yy - r) / max(1, h - 2 * r - 1)))
    layer.alpha_composite(sq, (x0 * K, y0 * K))
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur * K))
    img.alpha_composite(layer)


def artwork():
    """Overlapping coloured squares around the logo, in the spirit of the Win2000 boot art."""
    img = Image.new("RGBA", (640 * K, 290 * K), (0, 0, 0, 0))
    # soft yellow glow behind the red square
    square(img, (100, 98, 200, 160), ((255, 214, 90, 160), (255, 214, 90, 0)), None, blur=10)
    square(img, (98, 120, 250, 252), ((240, 70, 20, 235), (248, 96, 49, 235)),
           ((250, 120, 70, 235), (236, 60, 20, 235)), ring=16, blur=1.5)
    square(img, (463, 93, 556, 213), ((150, 205, 240, 230), (184, 231, 249, 230)),
           ((205, 241, 252, 230), (230, 248, 255, 230)), ring=12, blur=1.5)
    square(img, (345, 68, 462, 235), ((20, 60, 160, 240), (7, 42, 132, 240)),
           ((120, 150, 200, 240), (225, 233, 245, 240)), ring=14, blur=1)
    square(img, (255, 160, 372, 276), ((12, 50, 150, 245), (8, 40, 130, 245)),
           ((180, 200, 230, 245), (238, 242, 250, 245)), ring=12, blur=1)
    # red base under the centre tile, then the tile with a blue bevelled frame
    square(img, (166, 82, 334, 222), ((230, 50, 10, 255), (210, 40, 10, 255)), None)
    square(img, (180, 46, 342, 212), ((9, 87, 159, 255), (192, 218, 235, 255)),
           ((255, 255, 255, 255), (250, 250, 252, 255)), ring=10)
    # the centre tile stays empty: the boot script puts the system's logo there
    return img


VERSION_CHARS = "0123456789."
VERSION_FONT = (lib("LiberationSans-Regular.ttf"), 48)
VERSION_SPACING = -2


def glyph(c):
    """One character of the release number, on a fixed-height canvas (top = font ascent line)."""
    f = font(*VERSION_FONT)
    asc, desc = f.getmetrics()
    w = max(1, int(round(text_width(c, f, VERSION_SPACING) * K)))
    img = Image.new("RGBA", (w, asc + desc), (0, 0, 0, 0))
    text(ImageDraw.Draw(img), 0, 0, c, f, fill=(20, 20, 20), spacing=VERSION_SPACING)
    return img


def wordmark(product, tagline):
    """Big distribution name. Returns (image, (version_x, version_y, name_end)) in virtual
    px: the boot script draws the release number from glyphs/ at version_x/version_y and
    right-aligns tagline.png under the end of the version (or of the name)."""
    img = Image.new("RGBA", (640 * K, 90 * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, y0 = 122, 0
    size = 66
    while size > 30 and text_width(product, font(lib("LiberationSans-Bold.ttf"), size), -3.5 * size / 66) > 640 - x0 - 24:
        size -= 2
    f_title = font(lib("LiberationSans-Bold.ttf"), size)
    tw = text_width(product, f_title, -3.5 * size / 66)
    text(d, x0, y0 + (66 - size) * 0.8, product, f_title, spacing=-3.5 * size / 66)
    # version: 6px after the name, baseline-aligned with it; the tagline (tagline.png) is
    # right-aligned under the end of the version, or of the name, by the boot script
    asc_t = f_title.getmetrics()[0] / K
    asc_v = font(*VERSION_FONT).getmetrics()[0] / K
    return img, (round(x0 + tw + 6, 2), round(y0 + (66 - size) * 0.8 + asc_t - asc_v, 2), round(x0 + tw, 2))


def tagline_image(tagline):
    f_tag = font(TAHOMA_BOLD, 13)
    img = Image.new("RGBA", (int(text_width(tagline, f_tag) * K) + 2, 18 * K), (0, 0, 0, 0))
    text(ImageDraw.Draw(img), 0, 0, tagline, f_tag, fill=(20, 20, 20))
    return img


def band():
    """10px blue band above the grey strip (horizontal gradient + vertical shading)."""
    W, H = 640 * K, 10 * K
    img = Image.new("RGB", (W, H))
    across = [(0.0, (8, 80, 192)), (0.5, (10, 64, 160)), (1.0, (0, 119, 220))]
    shade = [(0.0, 1.35), (0.15, 1.0), (0.85, 1.0), (1.0, 1.2)]
    px = img.load()
    for x in range(W):
        c = gradient_at(across, x / (W - 1))
        for y in range(H):
            t = y / (H - 1)
            f = next(lerp((a,), (b,), (t - p0) / (p1 - p0))[0] if False else a + (b - a) * (t - p0) / (p1 - p0)
                     for (p0, a), (p1, b) in zip(shade, shade[1:]) if p0 <= t <= p1)
            px[x, y] = tuple(min(255, int(v * f)) for v in c)
    # light line on top, soft line at the bottom
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, K - 1], fill=(68, 102, 191))
    d.rectangle([0, H - K, W, H], fill=(160, 164, 201))
    return img


def main():
    GREY = (196, 196, 196)
    BLUE = (10, 89, 164)
    os.makedirs(os.path.join(OUT, "wordmarks"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "footers"), exist_ok=True)

    art = save(artwork(), "art.png")
    os.makedirs(os.path.join(OUT, "glyphs"), exist_ok=True)
    for c in VERSION_CHARS:
        save(glyph(c), os.path.join("glyphs", ("dot" if c == "." else c) + ".png"))
    for key, name in WORDMARKS.items():
        img, (vx, vy, name_end) = wordmark(name, TAGLINE)
        save(img, os.path.join("wordmarks", key + ".png"))
        with open(os.path.join(OUT, "wordmarks", key + ".txt"), "w") as f:
            f.write(f"version_x={vx}\nversion_y={vy}\nname_end={name_end}\n")
        foot = "Powered by KDE Plasma" if key == "generic" else name + "  with  KDE Plasma"
        save(label(foot, color=(40, 40, 40)), os.path.join("footers", key + ".png"))
    save(tagline_image(TAGLINE), "tagline.png")
    # defaults, replaced by the installer with the detected distribution's
    wm, wm_at = wordmark(WORDMARKS["generic"], TAGLINE)
    save(wm, "wordmark.png")
    save(label("Powered by KDE Plasma", color=(40, 40, 40)), "footer.png")

    f_brand = font(lib("LiberationSans-BoldItalic.ttf"), 26)
    br = Image.new("RGBA", (int(text_width("KDE", f_brand) + 4) * K, 34 * K), (0, 0, 0, 0))
    text(ImageDraw.Draw(br), 0, 1, "KDE", f_brand)
    save(br, "brand.png")

    bd = save(band(), "band.png")
    save(Image.new("RGB", (8, 8), GREY), "grey.png")

    save(label("Starting up...", color=(30, 30, 30)), "label-boot.png")
    save(label("Shutting down...", color=(30, 30, 30)), "label-shutdown.png")
    save(label("Restarting...", color=(30, 30, 30)), "label-reboot.png")

    # progress bar: thin sunken frame on the grey, blue blocks
    frame = Image.new("RGBA", (168 * K, 10 * K), GREY + (255,))
    d = ImageDraw.Draw(frame)
    rect(d, 0, 0, 168, 1, SHADOW); rect(d, 0, 0, 1, 10, SHADOW)
    rect(d, 0, 9, 168, 1, WHITE); rect(d, 167, 0, 1, 10, WHITE)
    save(frame, "progress-frame.png")
    save(Image.new("RGBA", (7 * K, 6 * K), BLUE + (255,)), "progress-block.png")

    dlg, field = password_dialog(["This computer's disk is encrypted.",
                                   "Type the password to start the computer."])
    save(dlg, "dialog.png")
    save(asterisk(), "asterisk.png")

    if "--preview" in sys.argv:
        # same maths as the boot script, for a 16:10 screen and 640x480 (no logo/icon)
        for name, (sw, sh) in (("preview.png", (1440, 900)), ("preview-4x3.png", (640, 480))):
            prev = render(sw, sh, art, wm, br, bd, frame, dlg, field, password=name == "preview.png",
                          version_at=wm_at,
                          prompt="Please enter passphrase for disk Samsung SSD 990 PRO 2TB (nvme0n1p3_crypt):")
            prev.convert("RGB").save(os.path.join(OUT, name))


def render(sw, sh, art, wm, br, bd, frame, dlg, field, password=False, logo=None, icon=None, blocks=8,
           version="", version_at=(0, 0), prompt=""):
    """Preview with the same maths as the boot script. logo/icon: optional PIL images."""
    s = min(sh / 480, sw / 640)
    ox = (sw - 640 * s) / 2
    oy = sh - 480 * s
    img = Image.new("RGBA", (sw, sh), WHITE + (255,))

    def put(im, x, y):
        w, h = max(1, int(im.width * s / K)), max(1, int(im.height * s / K))
        img.alpha_composite(im.resize((w, h), Image.LANCZOS), (int(x), int(y)))
        return w, h

    put(art, ox, oy + 10 * s)
    if logo is not None:  # fit inside LOGO_SIZE, centred on LOGO_CENTRE
        f = LOGO_SIZE * K / max(logo.width, logo.height)
        lg = logo.resize((int(logo.width * f), int(logo.height * f)), Image.LANCZOS)
        put(lg, ox + LOGO_CENTRE[0] * s - lg.width * s / K / 2, oy + 10 * s + LOGO_CENTRE[1] * s - lg.height * s / K / 2)
    put(wm, ox, oy + 280 * s)
    x = ox + version_at[0] * s
    for c in version:
        g = Image.open(os.path.join(OUT, "glyphs", ("dot" if c == "." else c) + ".png"))
        w, _ = put(g, x, oy + (280 + version_at[1]) * s)
        x += w
    end = x if version else ox + (version_at[2] if len(version_at) > 2 else 0) * s
    tg = Image.open(os.path.join(OUT, "tagline.png"))
    put(tg, end - tg.width * s / K, oy + (280 + 64) * s)
    bw = int(br.width * s / K)
    put(br, sw - bw - 20 * s, 10 * s)
    bottom = sh
    img.alpha_composite(bd.convert("RGBA").resize((sw, int(10 * s))), (0, int(bottom - 64 * s)))
    img.alpha_composite(Image.new("RGBA", (sw, int(54 * s) + 1), (196, 196, 196, 255)), (0, int(bottom - 54 * s)))
    cx = sw / 2
    lb = Image.open(os.path.join(OUT, "label-boot.png"))
    put(lb, cx - 58 * s - int(lb.width * s / K), bottom - 46 * s)  # right-aligned to the bar
    put(frame, cx - 52 * s, bottom - 43 * s)
    blk = Image.open(os.path.join(OUT, "progress-block.png"))
    for i in range(blocks):
        put(blk, cx - 52 * s + (2 + i * 9) * s, bottom - 43 * s + 2 * s)
    ft = Image.open(os.path.join(OUT, "footer.png"))
    fw = int(ft.width * s / K)
    put(ft, cx - fw / 2, bottom - 24 * s)
    if password:
        dx, dy = ox + 150 * s, oy + 140 * s
        put(dlg, dx, dy)
        if icon is not None:  # 4x pixel-doubled 32px icon
            put(icon, dx + 14 * s, dy + 34 * s)
        if prompt:  # Plymouth's prompt, fitted like the script's FitText (13px high, max 266 wide)
            f = ImageFont.truetype(lib("LiberationSans-Regular.ttf"), 96)
            l, t, r, b = f.getbbox(prompt)
            pi = Image.new("RGBA", (r, int(96 * 1.2)), (0, 0, 0, 0))
            ImageDraw.Draw(pi).text((0, 0), prompt, font=f, fill=(64, 64, 64))
            h = 13 * s
            w = pi.width * h / pi.height
            if w > 266 * s:
                h, w = h * 266 * s / w, 266 * s
            pi = pi.resize((int(w) + 1, int(h) + 1), Image.LANCZOS)
            img.alpha_composite(pi, (int(dx + 60 * s), int(dy + 66 * s)))
        ast = asterisk()
        for i in range(8):
            put(ast, dx + (field[0] + 4 + i * 8) * s, dy + field[1] * s)
    return img


if __name__ == "__main__":
    main()
