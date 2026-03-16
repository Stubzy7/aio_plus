"""Linux mouse control using xdotool.

Drop-in replacement for platform.win32.mouse — same public API.
"""

import subprocess
import time
import math


def _xdo_run(*args: str) -> str:
    """Run an xdotool command and return stdout."""
    try:
        result = subprocess.run(["xdotool"] + list(args),
                                capture_output=True, text=True, timeout=5)
        return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""


def _xdo(*args: str):
    """Run an xdotool command silently."""
    try:
        subprocess.run(["xdotool"] + list(args),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=5)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass


_BUTTON_MAP = {"left": "1", "middle": "2", "right": "3"}


def set_cursor_pos(x: int, y: int):
    """Move cursor to absolute position instantly."""
    _xdo("mousemove", "--sync", str(x), str(y))


def mouse_move(x: int, y: int, speed: int = 0):
    """Move cursor to position, optionally with interpolation.

    speed=0 means instant. speed>0 is number of intermediate steps.
    """
    if speed <= 0:
        set_cursor_pos(x, y)
        return

    # Interpolate movement
    cx, cy = get_cursor_pos()
    dx = x - cx
    dy = y - cy
    dist = math.hypot(dx, dy)
    steps = max(1, min(speed, int(dist / 2)))
    for i in range(1, steps + 1):
        t = i / steps
        ix = int(cx + dx * t)
        iy = int(cy + dy * t)
        _xdo("mousemove", "--sync", str(ix), str(iy))
        time.sleep(0.01)


def click(x=None, y=None, button="left", count=1):
    """Click at position (or current position if x/y are None)."""
    btn = _BUTTON_MAP.get(button, "1")
    args = []
    if x is not None and y is not None:
        args += ["mousemove", "--sync", str(x), str(y)]
        args += ["click", "--repeat", str(count), btn]
    else:
        args += ["click", "--repeat", str(count), btn]
    _xdo(*args)


def mouse_down(button="left"):
    """Press mouse button down."""
    btn = _BUTTON_MAP.get(button, "1")
    _xdo("mousedown", btn)


def mouse_up(button="left"):
    """Release mouse button."""
    btn = _BUTTON_MAP.get(button, "1")
    _xdo("mouseup", btn)


def get_cursor_pos() -> tuple[int, int]:
    """Get current cursor position as (x, y)."""
    output = _xdo_run("getmouselocation")
    # Output: x:123 y:456 screen:0 window:12345
    x, y = 0, 0
    for part in output.split():
        if part.startswith("x:"):
            x = int(part[2:])
        elif part.startswith("y:"):
            y = int(part[2:])
    return x, y
