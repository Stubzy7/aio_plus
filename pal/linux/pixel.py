import time

try:
    from PIL import ImageGrab
except ImportError:
    raise ImportError("Pillow is required: pip install Pillow")


def pixel_get_color(x: int, y: int) -> int:
    try:
        img = ImageGrab.grab(bbox=(x, y, x + 1, y + 1))
    except Exception as e:
        raise RuntimeError(
            "Screen capture failed. On Linux, install scrot: "
            "sudo apt install scrot (or sudo dnf install scrot)"
        ) from e
    r, g, b = img.getpixel((0, 0))[:3]
    return (r << 16) | (g << 8) | b


def px_get(x: int, y: int) -> int:
    return pixel_get_color(x, y)


def color_r(c: int) -> int:
    return (c >> 16) & 0xFF


def color_g(c: int) -> int:
    return (c >> 8) & 0xFF


def color_b(c: int) -> int:
    return c & 0xFF


def is_color_similar(c1: int, c2: int, tolerance: int = 30) -> bool:
    return (abs(color_r(c1) - color_r(c2))
            + abs(color_g(c1) - color_g(c2))
            + abs(color_b(c1) - color_b(c2))) <= tolerance


def pixel_search(x1: int, y1: int, x2: int, y2: int,
                 color: int, tolerance: int = 0) -> tuple | None:
    try:
        img = ImageGrab.grab(bbox=(x1, y1, x2 + 1, y2 + 1))
    except Exception:
        return None

    width, height = img.size
    pixels = img.load()
    tr = color_r(color)
    tg = color_g(color)
    tb = color_b(color)

    for py in range(height):
        for px in range(width):
            r, g, b = pixels[px, py][:3]
            if (abs(r - tr) <= tolerance and
                    abs(g - tg) <= tolerance and
                    abs(b - tb) <= tolerance):
                return (x1 + px, y1 + py)
    return None


def wait_for_pixel(x: int, y: int, color: int,
                   tolerance: int = 30, timeout_ms: int = 5000,
                   interval_ms: int = 50) -> bool:
    deadline = time.monotonic() + timeout_ms / 1000.0
    while time.monotonic() < deadline:
        current = pixel_get_color(x, y)
        if is_color_similar(current, color, tolerance):
            return True
        time.sleep(interval_ms / 1000.0)
    return False
