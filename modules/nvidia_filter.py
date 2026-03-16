
import time

from core.state import state
from input.pixel import px_get, pixel_search


# ---------------------------------------------------------------------------
#  Color distance / comparison
# ---------------------------------------------------------------------------

def nf_color_dist(c1: int, c2: int) -> int:
    """Max single-channel RGB distance between two 0xRRGGBB colors.

    Returns max(|r1-r2|, |g1-g2|, |b1-b2|).
    """
    r1 = (c1 >> 16) & 0xFF
    g1 = (c1 >> 8) & 0xFF
    b1 = c1 & 0xFF
    r2 = (c2 >> 16) & 0xFF
    g2 = (c2 >> 8) & 0xFF
    b2 = c2 & 0xFF
    return max(abs(r1 - r2), abs(g1 - g2), abs(b1 - b2))


def nf_changed(c_now: int, c_base: int, tol: int = 25) -> bool:
    """Return *True* if the current color has shifted from *c_base*.

    Used to detect UI state transitions even
    when absolute color targets are unreliable due to NF tinting.
    """
    return nf_color_dist(c_base, c_now) > tol


# ---------------------------------------------------------------------------
#  Pixel wait with NF fallback
# ---------------------------------------------------------------------------

def nf_pixel_wait(x: int, y: int, x2: int, y2: int,
                  color: int, tol: int = 0,
                  baseline: int = 0) -> tuple[bool, int]:
    """Single-poll pixel check that compensates for NF color shifts.

    Compensates for NF color shifts with widened tolerance and change detection.

    Args:
        x, y, x2, y2: Search rectangle (usually a small 4-5 px box).
        color:    Expected 0xRRGGBB target.
        tol:      Base tolerance.
        baseline: Previous pixel color at (x, y); 0 = not yet captured.

    Returns:
        ``(matched, baseline)`` — *matched* is True when the target color
        is found OR when a significant change from *baseline* is detected
        (NF mode only).
    """
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


# ---------------------------------------------------------------------------
#  Brightness / content helpers
# ---------------------------------------------------------------------------

def nf_is_bright(x: int, y: int, threshold: int = 200) -> bool:
    """Return *True* if the pixel at *(x, y)* is bright (white-ish).

    With NF enabled the threshold is relaxed
    and an average-brightness check is used instead of per-channel.
    """
    c = px_get(x, y)
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF

    if not state.nf_enabled:
        return r > threshold and g > threshold and b > threshold

    return (r + g + b) // 3 > max(threshold - 50, 120)


def nf_color_bright(c: int, threshold: int = 200) -> bool:
    """Same as :func:`nf_is_bright` but operates on a pre-read color int."""
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF

    if not state.nf_enabled:
        return r > threshold and g > threshold and b > threshold

    return (r + g + b) // 3 > max(threshold - 50, 120)


def nf_has_content(x: int, y: int, empty_baseline: int,
                   tol: int = 35) -> bool:
    """Return *True* if the slot at *(x, y)* contains items.

    Compares the live pixel against *empty_baseline* (the known color of
    an empty slot).
    """
    c = px_get(x, y)
    return nf_color_dist(c, empty_baseline) > tol


def nft(base: int, direction: int = 1) -> int:
    """NVIDIA filter threshold adjustment.

    Adjusts a threshold when NF is enabled.
    When NF enabled: ``max(0, min(255, base - direction * 35))``.
    When NF disabled: returns ``base`` unchanged.
    """
    if not state.nf_enabled:
        return base
    return max(0, min(255, base - direction * 35))


def nf_not_black(x: int, y: int, threshold: int = 15) -> bool:
    """Return *True* if the pixel at *(x, y)* is NOT black.

    Pixel is considered non-black when the
    sum of its RGB channels exceeds *threshold* (default 15).
    """
    c = px_get(x, y)
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF
    return (r + g + b) > threshold


def nf_search_tol(x1: int, y1: int, x2: int, y2: int,
                  color: int, tolerance: int = 0) -> tuple[int, int] | None:
    """Pixel search with NF-aware tolerance boost.

    Boosts tolerance by +45 (capped at 120) when NF is enabled.

    Returns:
        ``(x, y)`` of first match or *None*.
    """
    nf = state.nf_enabled
    actual_tol = min(tolerance + 45, 120) if nf else tolerance
    return pixel_search(x1, y1, x2, y2, color, actual_tol)
