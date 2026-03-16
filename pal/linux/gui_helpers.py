"""Linux GUI helpers.

Drop-in replacement for platform.win32.gui_helpers — same public API.
"""

from . import window as _win


def set_no_activate(hwnd_hex_str: str):
    """Set a window to not steal focus when shown.

    On Linux with Tk, overrideredirect(True) handles this.
    This function is a no-op.
    """
    pass


def flash_activate(hwnd: int) -> int:
    """Activate a window and return the previously active window."""
    return _win._flash_activate(hwnd)


def flash_restore(prev_hwnd: int, game_hwnd: int):
    """Restore focus to the previous window."""
    _win._flash_restore(prev_hwnd, game_hwnd)
