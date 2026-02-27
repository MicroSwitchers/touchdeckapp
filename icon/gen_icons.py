"""Generate all app icons from the TouchDeck SVG geometry using Pillow."""
from PIL import Image, ImageDraw
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def draw_icon(size):
    s = size / 512.0
    img = Image.new('RGBA', (size, size), (9, 9, 11, 255))
    draw = ImageDraw.Draw(img)

    # Purple speech-bubble rounded rect
    bx0, by0, bx1, by1 = round(100*s), round(110*s), round(412*s), round(320*s)
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=round(44*s), fill=(99, 102, 241, 255))

    # Bubble tail (triangle)
    tail = [
        (round(148*s), round(318*s)),
        (round(124*s), round(392*s)),
        (round(218*s), round(318*s)),
    ]
    draw.polygon(tail, fill=(99, 102, 241, 255))

    # Sound-wave bars (semi-transparent) on a separate overlay
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ov = ImageDraw.Draw(overlay)
    bar_r = max(1, round(17*s))

    # Left bar — opacity 0.85
    ov.rounded_rectangle([round(175*s), round(172*s), round(209*s), round(272*s)],
                         radius=bar_r, fill=(255, 255, 255, 217))
    # Centre bar — opacity 1.0
    ov.rounded_rectangle([round(239*s), round(148*s), round(273*s), round(296*s)],
                         radius=bar_r, fill=(255, 255, 255, 255))
    # Right bar — opacity 0.85
    ov.rounded_rectangle([round(303*s), round(172*s), round(337*s), round(272*s)],
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
