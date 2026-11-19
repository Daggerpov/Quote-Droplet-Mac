"""Composes the Mac App Store screenshots (2880x1800) from the rendered menu bar card:
a caption on the left, a menu bar at the top and the card dropping down from the droplet icon.

    ./render.sh <raw dir>/wisdom Wisdom 634
    ./render.sh <raw dir>/motivation Motivation 24
    ./render.sh <raw dir>/uplift Upliftment 221
    python3 make_store_screens.py <raw dir> <out dir>

Needs Pillow and macOS (system fonts).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 2880, 1800

# (raw subfolder, appearance, eyebrow, headline, subtitle)
SCREENS = [
    ("wisdom", "dark", "QUOTE DROPLET", "Wisdom in\nyour menu bar", "One click shows a new quote, from\nMarcus Aurelius to Maya Angelou."),
    ("motivation", "light", "CATEGORIES", "Pick what\ninspires you", "Wisdom, motivation, discipline,\nphilosophy and more."),
    ("uplift", "dark", "DAILY NOTIFICATION", "A quote a day,\nat your time", "Set the time once; copy any quote\nwith a click."),
    ("wisdom", "light", "LIGHT & DARK", "Made for your\nMac", "Follows your system appearance,\nin warm Espresso and Linen tones."),
]

THEMES = {
    # background top, background bottom, text, secondary text, accent, menu bar
    "dark": ("4A392F", "231A15", "F7EEDD", "CDBFAE", "E8B66B", (30, 22, 18, 150)),
    "light": ("FBF7F0", "E9DFD0", "3A2E27", "6E5F55", "A9492A", (255, 255, 255, 150)),
}

SERIF = "/System/Library/Fonts/NewYork.ttf"
SANS = "/System/Library/Fonts/SFNS.ttf"


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def font(path, size, axes):
    f = ImageFont.truetype(path, size)
    f.set_variation_by_axes(axes)
    return f


def draw_droplet(draw, cx, cy, size, fill):
    """A water drop: a circle with a point on top."""
    r = size * 0.36
    body_cy = cy + size * 0.14
    draw.ellipse((cx - r, body_cy - r, cx + r, body_cy + r), fill=fill)
    draw.polygon([(cx, cy - size * 0.5), (cx - r * 0.92, body_cy - r * 0.38), (cx + r * 0.92, body_cy - r * 0.38)], fill=fill)


def compose(card_path, out_path, appearance, eyebrow, headline, subtitle):
    top, bottom, text, secondary, accent, bar = THEMES[appearance]
    top, bottom, text, secondary, accent = rgb(top), rgb(bottom), rgb(text), rgb(secondary), rgb(accent)
    canvas = Image.new("RGBA", (W, H))
    draw = ImageDraw.Draw(canvas)
    for y in range(H):
        draw.line([(0, y), (W, y)], fill=mix(top, bottom, y / (H - 1)))
    # A soft glow behind the card.
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse((1500, 150, 2900, 1650), fill=70 if appearance == "dark" else 90)
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    canvas.paste(Image.new("RGBA", (W, H), accent + (255,)), (0, 0), glow.point(lambda v: v // 3))

    # Menu bar (24pt at 2x).
    bar_h = 48
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle((0, 0, W, bar_h), fill=bar)
    canvas = Image.alpha_composite(canvas, overlay)
    draw = ImageDraw.Draw(canvas)
    menu_font = font(SANS, 27, [100, 17, 400, 510])
    bar_text = text
    clock = "Wed Nov 18  9:41 AM"
    clock_w = draw.textlength(clock, font=menu_font)
    draw.text((W - 40 - clock_w, bar_h / 2), clock, font=menu_font, fill=bar_text, anchor="lm")
    # The status item, highlighted because its menu is open.
    icon_cx = W - 40 - clock_w - 70
    draw.rounded_rectangle((icon_cx - 30, 6, icon_cx + 30, bar_h - 6), radius=10,
                           fill=mix(rgb("FFFFFF"), bar_text, 0.75) + (90,) if appearance == "dark" else (0, 0, 0, 30))
    draw_droplet(draw, icon_cx, bar_h / 2 - 1, 26, accent)

    # The card, scaled up, under the icon.
    card = Image.open(card_path).convert("RGBA")
    scale = 1.95
    cw, ch = round(card.width * scale), round(card.height * scale)
    card = card.resize((cw, ch), Image.LANCZOS)
    radius = round(10 * 2 * scale)
    mask = Image.new("L", (cw, ch), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, cw - 1, ch - 1), radius=radius, fill=255)
    cx = min(W - 120 - cw, round(icon_cx - cw * 0.62))
    cy = bar_h + 70
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((cx, cy + 30, cx + cw, cy + ch + 30), radius=radius, fill=150 if appearance == "dark" else 80)
    shadow = shadow.filter(ImageFilter.GaussianBlur(50))
    canvas.paste(Image.new("RGBA", (W, H), (0, 0, 0, 255)), (0, 0), shadow)
    draw = ImageDraw.Draw(canvas)
    edge = (255, 255, 255, 40) if appearance == "dark" else (0, 0, 0, 30)
    draw.rounded_rectangle((cx - 3, cy - 3, cx + cw + 2, cy + ch + 2), radius=radius + 3, fill=edge)
    canvas.paste(card, (cx, cy), mask)

    # Caption on the left, centered vertically in the free space.
    draw = ImageDraw.Draw(canvas)
    eyebrow_font = font(SANS, 46, [100, 28, 400, 640])
    headline_font = font(SERIF, 150, [40, 640, 0])
    sub_font = font(SANS, 54, [100, 28, 400, 430])
    left = 200
    head_box = draw.multiline_textbbox((0, 0), headline, font=headline_font, spacing=24)
    sub_box = draw.multiline_textbbox((0, 0), subtitle, font=sub_font, spacing=18)
    block_h = 60 + 50 + (head_box[3] - head_box[1]) + 70 + (sub_box[3] - sub_box[1])
    y = (H + bar_h - block_h) / 2
    x = left
    for chr_ in eyebrow:
        draw.text((x, y), chr_, font=eyebrow_font, fill=accent)
        x += draw.textlength(chr_, font=eyebrow_font) + 7
    y += 60 + 50
    draw.multiline_text((left, y - head_box[1]), headline, font=headline_font, fill=text, spacing=24)
    y += head_box[3] - head_box[1] + 70
    draw.multiline_text((left, y - sub_box[1]), subtitle, font=sub_font, fill=secondary, spacing=18)

    canvas.convert("RGB").save(out_path, "PNG")


def main():
    raw_dir, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    for n, (folder, appearance, eyebrow, headline, subtitle) in enumerate(SCREENS, 1):
        card = os.path.join(raw_dir, folder, f"menu_{appearance}.png")
        out = os.path.join(out_dir, f"{n:02d}-{folder}-{appearance}.png")
        compose(card, out, appearance, eyebrow, headline, subtitle)
        print(out)


if __name__ == "__main__":
    main()
