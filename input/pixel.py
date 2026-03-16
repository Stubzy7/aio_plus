from pal import pixel as _p

pixel_get_color = _p.pixel_get_color
px_get = _p.px_get
color_r = _p.color_r
color_g = _p.color_g
color_b = _p.color_b
is_color_similar = _p.is_color_similar
pixel_search = _p.pixel_search


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
