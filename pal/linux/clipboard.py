"""Linux clipboard using xclip.

Drop-in replacement for platform.win32.clipboard — same public API.
"""

import subprocess
from contextlib import contextmanager


@contextmanager
def win32_clipboard():
    """Context manager for clipboard access.

    On Windows this wraps OpenClipboard/CloseClipboard.
    On Linux, xclip handles locking internally, so this is a no-op wrapper.
    """
    yield None


def get_clipboard_text() -> str | None:
    """Get text from the system clipboard."""
    try:
        result = subprocess.run(
            ["xclip", "-selection", "clipboard", "-o"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            return result.stdout
        return None
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None


def set_clipboard_text(text: str) -> bool:
    """Set text on the system clipboard."""
    try:
        result = subprocess.run(
            ["xclip", "-selection", "clipboard"],
            input=text, text=True, timeout=5,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False
