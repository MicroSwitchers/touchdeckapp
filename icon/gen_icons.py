"""Generate all app icons from the TouchDeck SVG geometry using Pillow."""
from PIL import Image, ImageDraw
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def draw_icon(size):
    s = size / 512.0
    img = Image.new('RGBA', (size, size), (9, 9, 11, 255))
    draw = ImageDraw.Draw(img)

    # ── Lighter bubble behind (rect2-9): x=157, y=108, w=232, h=210, rx=116 ──
    # Visible only on the right edge beyond the main bubble — gives a subtle rim highlight
    lx0, ly0 = round(157*s), round(108*s)
    lx1, ly1 = round(389*s), round(318*s)
    draw.rounded_rectangle([lx0, ly0, lx1, ly1], radius=round(116*s),
                            fill=(146, 146, 244, 255))

    # ── Main bubble (rect2): x=140, y=110, w=232, h=210, rx=116, #6366f1 ──
    bx0, by0 = round(140*s), round(110*s)
    bx1, by1 = round(372*s), round(320*s)
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=round(116*s),
                            fill=(99, 102, 241, 255))

    # ── Radial highlight overlay (approximation of radialGradient, rect2-2) ──
    # A soft lighter ellipse centred ~(256,195) fading to transparent
    hl = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    hl_draw = ImageDraw.Draw(hl)
    for i in range(20, 0, -1):
        r_w = round(107*s * i / 20)
        r_h = round(96*s  * i / 20)
        cx, cy = round(233*s), round(215*s)
        alpha = round(38 * (1 - i / 20))   # max ~38, fades to 0 at centre
        hl_draw.ellipse([cx - r_w, cy - r_h, cx + r_w, cy + r_h],
                        fill=(145, 147, 245, alpha))
    img = Image.alpha_composite(img, hl)
    draw = ImageDraw.Draw(img)

    # ── Bubble tail (polygon2): points 148,318 / 124,392 / 218,318 + translate(32,−30) ──
    tail = [
        (round(180*s), round(288*s)),
        (round(156*s), round(362*s)),
        (round(250*s), round(288*s)),
    ]
    draw.polygon(tail, fill=(99, 102, 241, 255))

    # ── Sound-wave bars ──
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ov = ImageDraw.Draw(overlay)
    bar_r = max(1, round(15*s))

    # Left bar  — x=184, y=174, w=30, h=89, opacity 0.85
    ov.rounded_rectangle([round(184*s), round(174*s),
                           round(214*s), round(263*s)],
                          radius=bar_r, fill=(255, 255, 255, 217))
    # Centre bar — x=241, y=152, w=30, h=131, opacity 1.0
    ov.rounded_rectangle([round(241*s), round(152*s),
                           round(271*s), round(283*s)],
                          radius=bar_r, fill=(255, 255, 255, 255))
    # Right bar  — x=298, y=174, w=30, h=89, opacity 0.85
    ov.rounded_rectangle([round(298*s), round(174*s),
                           round(328*s), round(263*s)],
                          radius=bar_r, fill=(255, 255, 255, 217))

    img = Image.alpha_composite(img, overlay)
    return img

def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # Convert to RGB for files that must be RGB (favicon), keep RGBA for PNGs
    img.save(path)
    print(f"  Saved {os.path.relpath(path, BASE_DIR)}")

icon512 = draw_icon(512)
icon192 = draw_icon(192)
icon32  = draw_icon(32)
icon1024 = draw_icon(1024)

# Main icon PNG (used by flutter_launcher_icons)
save(icon1024, os.path.join(BASE_DIR, 'icon', 'icon.png'))

# Web PWA icons
web_icons = os.path.join(BASE_DIR, 'web', 'icons')
save(icon192, os.path.join(web_icons, 'Icon-192.png'))
save(icon512, os.path.join(web_icons, 'Icon-512.png'))
save(icon192, os.path.join(web_icons, 'Icon-maskable-192.png'))
save(icon512, os.path.join(web_icons, 'Icon-maskable-512.png'))

# Favicon
save(icon32, os.path.join(BASE_DIR, 'web', 'favicon.png'))

print("Done!")
