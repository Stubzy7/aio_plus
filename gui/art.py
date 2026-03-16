
import math
from PIL import Image, ImageDraw, ImageFont


# ---------------------------------------------------------------------------
#  Color helpers
# ---------------------------------------------------------------------------

def _spiral_color(frac: float) -> tuple[int, int, int]:
    """Map iteration fraction (0=outer, 1=inner) to an RGB color."""
    if frac < 0.10:   return (0x55, 0x08, 0x08)
    elif frac < 0.20: return (0x77, 0x10, 0x10)
    elif frac < 0.25: return (0x99, 0x18, 0x18)
    elif frac < 0.35: return (0xBB, 0x22, 0x22)
    elif frac < 0.45: return (0xDD, 0x30, 0x30)
    elif frac < 0.55: return (0xFF, 0x40, 0x40)
    elif frac < 0.65: return (0xFF, 0x66, 0x66)
    elif frac < 0.75: return (0xFF, 0x99, 0x99)
    elif frac < 0.85: return (0xFF, 0xCC, 0xCC)
    elif frac < 0.92: return (0xFF, 0xE0, 0xE0)
    else:             return (0xFF, 0xF0, 0xF0)


# ---------------------------------------------------------------------------
#  ART 1: Delta Spiral
# ---------------------------------------------------------------------------

def render_delta_spiral() -> Image.Image:
    """Render the inverted triangle spiral as a Pillow Image.

    Returns a 175x145 bitmap with black background.
    """
    radius = 85
    steps = 32
    slide = 0.068
    a0 = math.pi / 2

    bmp_w, bmp_h = 175, 175
    cx = 350 - 275  # 75
    cy = 140 - 75   # 65

    # Render at 2x for anti-aliasing
    scale = 2
    img = Image.new("RGB", (bmp_w * scale, bmp_h * scale), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    sx, sy = cx * scale, cy * scale
    sr = radius * scale

    p1x = sx + sr * math.cos(a0)
    p1y = sy + sr * math.sin(a0)
    p2x = sx + sr * math.cos(a0 + 2.0943951024)
    p2y = sy + sr * math.sin(a0 + 2.0943951024)
    p3x = sx + sr * math.cos(a0 + 4.1887902048)
    p3y = sy + sr * math.sin(a0 + 4.1887902048)

    for i in range(steps):
        frac = i / (steps - 1)
        alpha = int((1.0 - frac * 0.2) * 255)
        alpha = max(3, min(255, alpha))
        pw = max(1, int(round((max(0.5, 2.0 - frac * 1.2)) * scale)))

        color = _spiral_color(frac)
        r = color[0] * alpha // 255
        g = color[1] * alpha // 255
        b = color[2] * alpha // 255

        segments = [
            (p1x, p1y, p2x, p2y),
            (p2x, p2y, p3x, p3y),
            (p3x, p3y, p1x, p1y),
        ]
        for x1, y1, x2, y2 in segments:
            draw.line([(x1, y1), (x2, y2)], fill=(r, g, b), width=pw)

        n1x = p1x + slide * (p2x - p1x)
        n1y = p1y + slide * (p2y - p1y)
        n2x = p2x + slide * (p3x - p2x)
        n2y = p2y + slide * (p3y - p2y)
        n3x = p3x + slide * (p1x - p3x)
        n3y = p3y + slide * (p1y - p3y)
        p1x, p1y = n1x, n1y
        p2x, p2y = n2x, n2y
        p3x, p3y = n3x, n3y

    # Downscale with LANCZOS for anti-aliasing
    img = img.resize((bmp_w, bmp_h), Image.LANCZOS)
    return img


# ---------------------------------------------------------------------------
#  ART 2: GG Relief Text
# ---------------------------------------------------------------------------

# (text, gui_x, gui_y, color_rgb)
_GG_LINES = [
    (r"_____/\\\\\\\\\\\\_____/\\\\\\\\\\\\_",                    248, 330, (0xFF, 0xAA, 0xAA)),
    (r" ___/\\\//////////____/\\\//////////__",                     248, 338, (0xFF, 0x77, 0x77)),
    (r"  __/\\\______________/\\\_____________",                    248, 346, (0xFF, 0x55, 0x55)),
    (r"   _\/\\\____/\\\\\\\_\/\\\____/\\\\\\\_",                  248, 354, (0xFF, 0x40, 0x40)),
    (r"    _\/\\\___\/////\\\_\/\\\___\/////\\\_",                  248, 362, (0xDD, 0x30, 0x30)),
    (r"     _\/\\\_______\/\\\_\/\\\_______\/\\\_",                 248, 370, (0xBB, 0x22, 0x22)),
    (r"      _\/\\\_______\/\\\_\/\\\_______\/\\\_",                248, 378, (0x99, 0x18, 0x18)),
    (r"       _\//\\\\\\\\\\\\/__\//\\\\\\\\\\\\/__",              248, 386, (0x77, 0x10, 0x10)),
    (r"        __\////////////_____\////////////____",              248, 394, (0x55, 0x08, 0x08)),
]

# (x, y, color) for pipe staircase characters
_GG_PIPES = [
    (245, 338, (0xFF, 0x77, 0x77)),
    (245, 346, (0xFF, 0x55, 0x55)), (249, 346, (0xFF, 0x55, 0x55)),
    (245, 354, (0xFF, 0x40, 0x40)), (249, 354, (0xFF, 0x40, 0x40)), (253, 354, (0xFF, 0x40, 0x40)),
    (245, 362, (0xDD, 0x30, 0x30)), (249, 362, (0xDD, 0x30, 0x30)), (253, 362, (0xDD, 0x30, 0x30)), (257, 362, (0xDD, 0x30, 0x30)),
    (245, 370, (0xBB, 0x22, 0x22)), (249, 370, (0xBB, 0x22, 0x22)), (253, 370, (0xBB, 0x22, 0x22)), (257, 370, (0xBB, 0x22, 0x22)), (261, 370, (0xBB, 0x22, 0x22)),
    (245, 378, (0x99, 0x18, 0x18)), (249, 378, (0x99, 0x18, 0x18)), (253, 378, (0x99, 0x18, 0x18)), (257, 378, (0x99, 0x18, 0x18)), (261, 378, (0x99, 0x18, 0x18)), (265, 378, (0x99, 0x18, 0x18)),
    (245, 386, (0x77, 0x10, 0x10)), (249, 386, (0x77, 0x10, 0x10)), (253, 386, (0x77, 0x10, 0x10)), (257, 386, (0x77, 0x10, 0x10)), (261, 386, (0x77, 0x10, 0x10)), (265, 386, (0x77, 0x10, 0x10)), (269, 386, (0x77, 0x10, 0x10)),
    (245, 394, (0x55, 0x08, 0x08)), (249, 394, (0x55, 0x08, 0x08)), (253, 394, (0x55, 0x08, 0x08)), (257, 394, (0x55, 0x08, 0x08)), (261, 394, (0x55, 0x08, 0x08)), (265, 394, (0x55, 0x08, 0x08)), (269, 394, (0x55, 0x08, 0x08)), (273, 394, (0x55, 0x08, 0x08)),
]


def render_gg_art() -> Image.Image:
    """Render the GG Relief ASCII art as a Pillow Image.

    Returns a 210x140 bitmap with black background.
    """
    bmp_x, bmp_y = 240, 268
    bmp_w, bmp_h = 210, 140

    # Render at 2x for sharper text
    scale = 2
    img = Image.new("RGB", (bmp_w * scale, bmp_h * scale), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Load Consolas Bold — 5.5pt maps to ~8px in Pillow
    font_size = 8 * scale
    try:
        font = ImageFont.truetype("consolab.ttf", font_size)
    except OSError:
        try:
            font = ImageFont.truetype("consola.ttf", font_size)
        except OSError:
            font = ImageFont.load_default()

    # Draw text lines
    for text, gx, gy, color in _GG_LINES:
        x = (gx - bmp_x) * scale
        y = (gy - bmp_y) * scale
        draw.text((x, y), text, fill=color, font=font)

    # Draw pipe staircase
    for px, py, color in _GG_PIPES:
        x = (px - bmp_x) * scale
        y = (py - bmp_y) * scale
        draw.text((x, y), "|", fill=color, font=font)

    # Downscale
    img = img.resize((bmp_w, bmp_h), Image.LANCZOS)
    return img
