"""Linux window management using xdotool.

Drop-in replacement for platform.win32.window — same public API.
"""

import subprocess


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


def _get_class_name(hwnd: int) -> str:
    """Get the window class name (best-effort via xprop)."""
    try:
        result = subprocess.run(
            ["xprop", "-id", str(hwnd), "WM_CLASS"],
            capture_output=True, text=True, timeout=2
        )
        # Output like: WM_CLASS(STRING) = "class", "Class"
        if "=" in result.stdout:
            return result.stdout.split("=", 1)[1].strip().strip('"')
    except Exception:
        pass
    return ""


def find_window(class_name=None, title=None) -> int:
    """Find a window by class name or title. Returns window ID or 0."""
    args = ["search"]
    if class_name:
        args += ["--class", class_name]
    if title:
        args += ["--name", title]
    if not class_name and not title:
        return 0
    output = _xdo_run(*args)
    if output:
        # Return first window ID
        first_line = output.split('\n')[0].strip()
        if first_line.isdigit():
            return int(first_line)
    return 0


def win_exist(title: str) -> int:
    """Check if a window with given title exists. Returns window ID or 0."""
    return find_window(title=title)


def win_activate(hwnd: int):
    """Activate (focus) a window."""
    _xdo("windowactivate", "--sync", str(hwnd))


def win_get_pos(hwnd: int) -> tuple[int, int, int, int]:
    """Get window position and size as (x, y, width, height)."""
    output = _xdo_run("getwindowgeometry", "--shell", str(hwnd))
    # Output format:
    # WINDOW=12345
    # X=100
    # Y=200
    # WIDTH=800
    # HEIGHT=600
    x, y, w, h = 0, 0, 0, 0
    for line in output.split('\n'):
        line = line.strip()
        if line.startswith("X="):
            x = int(line[2:])
        elif line.startswith("Y="):
            y = int(line[2:])
        elif line.startswith("WIDTH="):
            w = int(line[6:])
        elif line.startswith("HEIGHT="):
            h = int(line[7:])
    return x, y, w, h


def win_move(hwnd: int, x: int, y: int, w: int = 0, h: int = 0):
    """Move and optionally resize a window."""
    _xdo("windowmove", str(hwnd), str(x), str(y))
    if w > 0 and h > 0:
        _xdo("windowsize", str(hwnd), str(w), str(h))


def find_input_child(hwnd: int) -> int:
    """Find the input child control of a window.

    On Linux, there is no separate HWND for input controls — just return
    the window ID itself.
    """
    return hwnd


def control_click(hwnd: int, x: int, y: int):
    """Click at window-relative coordinates using xdotool.

    Moves mouse to window-relative position and clicks.
    """
    _xdo("mousemove", "--window", str(hwnd), "--sync", str(x), str(y))
    _xdo("click", "--window", str(hwnd), "1")


def get_client_rect(hwnd: int) -> tuple[int, int, int, int]:
    """Get client rectangle of a window as (x, y, width, height).

    On Linux with xdotool, client area == window geometry.
    """
    return win_get_pos(hwnd)


def is_window_visible(hwnd: int) -> bool:
    """Check if a window is visible (mapped)."""
    # xdotool getwindowgeometry will fail for unmapped windows
    output = _xdo_run("getwindowgeometry", str(hwnd))
    return len(output) > 0


def get_foreground_window() -> int:
    """Get the currently active (foreground) window ID."""
    output = _xdo_run("getactivewindow")
    if output.strip().isdigit():
        return int(output.strip())
    return 0


def _flash_activate(hwnd: int) -> int:
    """Activate a window and return the previously active window.

    Used for brief focus-steal-and-restore patterns.
    """
    prev = get_foreground_window()
    win_activate(hwnd)
    return prev


def _flash_restore(prev_hwnd: int, game_hwnd: int):
    """Restore focus to the previous window after a flash_activate."""
    if prev_hwnd and prev_hwnd != game_hwnd:
        win_activate(prev_hwnd)
    else:
        win_activate(game_hwnd)
