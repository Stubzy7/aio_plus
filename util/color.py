
def color_r(c: int) -> int:
    """Extract red from 0xRRGGBB."""
    return (c >> 16) & 0xFF


def color_g(c: int) -> int:
    """Extract green from 0xRRGGBB."""
    return (c >> 8) & 0xFF


def color_b(c: int) -> int:
    """Extract blue from 0xRRGGBB."""
    return c & 0xFF


def is_color_similar(c1: int, c2: int, tolerance: int = 30) -> bool:
    """Check if two colors are within tolerance (sum of channel differences).

    Sum of per-channel absolute differences must be <= tolerance.
    """
    return (abs(color_r(c1) - color_r(c2))
            + abs(color_g(c1) - color_g(c2))
            + abs(color_b(c1) - color_b(c2))) <= tolerance


def color_distance(c1: int, c2: int) -> int:
    """Max single-channel distance between two colors."""
    return max(
        abs(color_r(c1) - color_r(c2)),
        abs(color_g(c1) - color_g(c2)),
        abs(color_b(c1) - color_b(c2)),
    )


def hex_to_int(hex_str: str) -> int:
    """Convert '0xRRGGBB' or 'RRGGBB' string to integer."""
    s = hex_str.strip().lower()
    if s.startswith("0x"):
        s = s[2:]
    return int(s, 16)


def int_to_hex(c: int) -> str:
    """Convert integer to '0xRRGGBB' string."""
    return f"0x{c:06X}"


def is_bright(c: int, threshold: int = 160) -> bool:
    """Check if a color is bright (any channel above threshold)."""
    return color_r(c) > threshold or color_g(c) > threshold or color_b(c) > threshold


def color_brightness(c: int) -> int:
    """Simple brightness as max channel value."""
    return max(color_r(c), color_g(c), color_b(c))
