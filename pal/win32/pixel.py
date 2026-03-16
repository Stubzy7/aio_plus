
import ctypes
import ctypes.wintypes as wt

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32

# GDI constants
SRCCOPY = 0x00CC0020
DIB_RGB_COLORS = 0


def get_dc():
    """Get device context for the entire screen."""
    return user32.GetDC(0)


def release_dc(hdc):
    """Release a device context obtained from get_dc."""
    user32.ReleaseDC(0, hdc)


def pixel_get_color(x: int, y: int) -> int:
    """Get the color of a pixel at screen coordinates (x, y).

    Returns color in 0xRRGGBB format.
    """
    hdc = get_dc()
    try:
        bgr = gdi32.GetPixel(hdc, x, y)
        if bgr == -1:
            return 0
        # Swap BGR -> RGB
        r = bgr & 0xFF
        g = (bgr >> 8) & 0xFF
        b = (bgr >> 16) & 0xFF
        return (r << 16) | (g << 8) | b
    finally:
        release_dc(hdc)


def px_get(x: int, y: int) -> int:
    """Alias for pixel_get_color."""
    return pixel_get_color(x, y)


def color_r(c: int) -> int:
    """Extract red component from 0xRRGGBB."""
    return (c >> 16) & 0xFF


def color_g(c: int) -> int:
    """Extract green component from 0xRRGGBB."""
    return (c >> 8) & 0xFF


def color_b(c: int) -> int:
    """Extract blue component from 0xRRGGBB."""
    return c & 0xFF


def is_color_similar(c1: int, c2: int, tolerance: int = 30) -> bool:
    """Check if two colors are similar within tolerance (sum of channel diffs).

    Sum of per-channel absolute differences must be <= tol.
    """
    return (abs(color_r(c1) - color_r(c2))
            + abs(color_g(c1) - color_g(c2))
            + abs(color_b(c1) - color_b(c2))) <= tolerance


def pixel_search(x1: int, y1: int, x2: int, y2: int, color: int,
                 tolerance: int = 0) -> tuple[int, int] | None:
    """Search for a pixel of the given color in a rectangular region.

    Returns (x, y) of the first match, or None if not found.
    Uses BitBlt for faster scanning of large regions.
    """
    width = x2 - x1 + 1
    height = y2 - y1 + 1
    if width <= 0 or height <= 0:
        return None

    # Optimise single-pixel check — skip BitBlt overhead
    if width == 1 and height == 1:
        c = px_get(x1, y1)
        if is_color_similar(c, color, tolerance):
            return (x1, y1)
        return None

    hdc_screen = get_dc()
    hdc_mem = gdi32.CreateCompatibleDC(hdc_screen)
    hbmp = gdi32.CreateCompatibleBitmap(hdc_screen, width, height)
    old_bmp = gdi32.SelectObject(hdc_mem, hbmp)

    gdi32.BitBlt(hdc_mem, 0, 0, width, height, hdc_screen, x1, y1, SRCCOPY)

    # Read pixel data into buffer
    class BITMAPINFOHEADER(ctypes.Structure):
        _fields_ = [
            ("biSize", wt.DWORD), ("biWidth", wt.LONG), ("biHeight", wt.LONG),
            ("biPlanes", wt.WORD), ("biBitCount", wt.WORD),
            ("biCompression", wt.DWORD), ("biSizeImage", wt.DWORD),
            ("biXPelsPerMeter", wt.LONG), ("biYPelsPerMeter", wt.LONG),
            ("biClrUsed", wt.DWORD), ("biClrImportant", wt.DWORD),
        ]

    bmi = BITMAPINFOHEADER()
    bmi.biSize = ctypes.sizeof(BITMAPINFOHEADER)
    bmi.biWidth = width
    bmi.biHeight = -height  # top-down
    bmi.biPlanes = 1
    bmi.biBitCount = 32
    bmi.biCompression = 0

    buf_size = width * height * 4
    buf = (ctypes.c_ubyte * buf_size)()
    gdi32.GetDIBits(hdc_mem, hbmp, 0, height, buf, ctypes.byref(bmi), DIB_RGB_COLORS)

    gdi32.SelectObject(hdc_mem, old_bmp)
    gdi32.DeleteObject(hbmp)
    gdi32.DeleteDC(hdc_mem)
    release_dc(hdc_screen)

    # Search buffer (BGRA format)
    target_r = color_r(color)
    target_g = color_g(color)
    target_b = color_b(color)

    for row in range(height):
        offset = row * width * 4
        for col in range(width):
            idx = offset + col * 4
            b, g, r = buf[idx], buf[idx + 1], buf[idx + 2]
            if (abs(r - target_r) <= tolerance
                    and abs(g - target_g) <= tolerance
                    and abs(b - target_b) <= tolerance):
                return (x1 + col, y1 + row)

    return None


def wait_for_pixel(x: int, y: int, color: int, tolerance: int = 30,
                   timeout_ms: int = 5000, interval_ms: int = 50) -> bool:
    """Wait until the pixel at (x, y) matches the target color.

    Returns True if matched within timeout, False otherwise.
    When NF (NVIDIA Filter) is enabled, delegates to nf_pixel_wait for
    expanded search area (+-2px).
    """
    import time
    from core.state import state as _st

    # NF-aware path: use expanded search area via nf_pixel_wait
    if getattr(_st, "nf_enabled", False):
        try:
            from modules.nvidia_filter import nf_pixel_wait
            return nf_pixel_wait(x, y, color, tolerance, timeout_ms)
        except (ImportError, AttributeError):
            pass  # Fall through to basic path

    deadline = time.perf_counter() + timeout_ms / 1000.0
    while time.perf_counter() < deadline:
        if is_color_similar(pixel_get_color(x, y), color, tolerance):
            return True
        time.sleep(interval_ms / 1000.0)
    return False
