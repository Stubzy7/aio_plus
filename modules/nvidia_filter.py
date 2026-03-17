
import time

from core.state import state
from input.pixel import px_get, pixel_search


def nf_color_dist(c1: int, c2: int) -> int:
    r1 = (c1 >> 16) & 0xFF
    g1 = (c1 >> 8) & 0xFF
    b1 = c1 & 0xFF
    r2 = (c2 >> 16) & 0xFF
    g2 = (c2 >> 8) & 0xFF
    b2 = c2 & 0xFF
    return max(abs(r1 - r2), abs(g1 - g2), abs(b1 - b2))


def nf_changed(c_now: int, c_base: int, tol: int = 25) -> bool:
    # Detects UI state transitions even when absolute color targets are unreliable due to NF tinting
    return nf_color_dist(c_base, c_now) > tol


def nf_pixel_wait(x: int, y: int, x2: int, y2: int,
                  color: int, tol: int = 0,
                  baseline: int = 0) -> tuple[bool, int]:
    nf = state.nf_enabled

    if not nf:
        result = pixel_search(x, y, x2, y2, color, tol)
        return (result is not None, baseline)

    # With NF: widen tolerance
    result = pixel_search(x, y, x2, y2, color, min(tol + 45, 120))
    if result is not None:
        return (True, baseline)

    # Fallback — detect *any* change from captured baseline
    if baseline == 0:
        baseline = px_get(x, y)
    current = px_get(x, y)
    return (nf_changed(current, baseline), baseline)


def nf_is_bright(x: int, y: int, threshold: int = 200) -> bool:
    c = px_get(x, y)
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF

    if not state.nf_enabled:
        return r > threshold and g > threshold and b > threshold

    return (r + g + b) // 3 > max(threshold - 50, 120)


def nf_color_bright(c: int, threshold: int = 200) -> bool:
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF

    if not state.nf_enabled:
        return r > threshold and g > threshold and b > threshold

    return (r + g + b) // 3 > max(threshold - 50, 120)


def nf_has_content(x: int, y: int, empty_baseline: int,
                   tol: int = 35) -> bool:
    c = px_get(x, y)
    return nf_color_dist(c, empty_baseline) > tol


def nft(base: int, direction: int = 1) -> int:
    if not state.nf_enabled:
        return base
    return max(0, min(255, base - direction * 35))


def nf_not_black(x: int, y: int, threshold: int = 15) -> bool:
    c = px_get(x, y)
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF
    return (r + g + b) > threshold


def nf_search_tol(x1: int, y1: int, x2: int, y2: int,
                  color: int, tolerance: int = 0) -> tuple[int, int] | None:
    nf = state.nf_enabled
    actual_tol = min(tolerance + 45, 120) if nf else tolerance
    return pixel_search(x1, y1, x2, y2, color, actual_tol)
