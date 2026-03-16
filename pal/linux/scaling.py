"""Linux screen resolution and DPI.

Drop-in replacement for platform.win32.scaling — same public API.
"""

import subprocess


def get_screen_size() -> tuple[int, int]:
    """Get primary screen resolution as (width, height)."""
    # Try xdotool first
    try:
        result = subprocess.run(
            ["xdotool", "getdisplaygeometry"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            parts = result.stdout.strip().split()
            if len(parts) == 2:
                return int(parts[0]), int(parts[1])
    except (FileNotFoundError, subprocess.TimeoutExpired, ValueError):
        pass

    # Fallback to tkinter
    try:
        import tkinter as tk
        root = tk.Tk()
        root.withdraw()
        w = root.winfo_screenwidth()
        h = root.winfo_screenheight()
        root.destroy()
        return w, h
    except Exception:
        pass

    return 1920, 1080


def set_dpi_aware():
    """Set DPI awareness. No-op on Linux."""
    pass
