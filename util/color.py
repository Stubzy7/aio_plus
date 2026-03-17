
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


def color_distance(c1: int, c2: int) -> int:
    return max(
        abs(color_r(c1) - color_r(c2)),
        abs(color_g(c1) - color_g(c2)),
        abs(color_b(c1) - color_b(c2)),
    )


def hex_to_int(hex_str: str) -> int:
    s = hex_str.strip().lower()
    if s.startswith("0x"):
        s = s[2:]
    return int(s, 16)


def int_to_hex(c: int) -> str:
    return f"0x{c:06X}"


def is_bright(c: int, threshold: int = 160) -> bool:
    return color_r(c) > threshold or color_g(c) > threshold or color_b(c) > threshold


def color_brightness(c: int) -> int:
    return max(color_r(c), color_g(c), color_b(c))
