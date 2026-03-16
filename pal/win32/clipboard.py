
import ctypes
import ctypes.wintypes as wt
from contextlib import contextmanager

_u32 = ctypes.windll.user32
_k32 = ctypes.windll.kernel32

# Set proper 64-bit return types once at import
_k32.GlobalAlloc.restype = ctypes.c_void_p
_k32.GlobalAlloc.argtypes = [wt.UINT, ctypes.c_size_t]
_k32.GlobalLock.restype = ctypes.c_void_p
_k32.GlobalLock.argtypes = [ctypes.c_void_p]
_k32.GlobalUnlock.argtypes = [ctypes.c_void_p]
_k32.GlobalFree.argtypes = [ctypes.c_void_p]
_u32.GetClipboardData.restype = ctypes.c_void_p
_u32.SetClipboardData.restype = ctypes.c_void_p
_u32.SetClipboardData.argtypes = [wt.UINT, ctypes.c_void_p]

CF_UNICODETEXT = 13


@contextmanager
def win32_clipboard():
    """Context manager for safe Win32 clipboard access.

    Ensures CloseClipboard is always called, even on error.

    Usage::

        with win32_clipboard() as u32:
            u32.EmptyClipboard()
            ...
    """
    if not _u32.OpenClipboard(0):
        raise RuntimeError("Failed to open clipboard")
    try:
        yield _u32
    finally:
        _u32.CloseClipboard()


def get_clipboard_text() -> str | None:
    """Read current clipboard text, or None if empty/unavailable."""
    try:
        with win32_clipboard():
            h = _u32.GetClipboardData(CF_UNICODETEXT)
            if not h:
                return None
            p = _k32.GlobalLock(h)
            if not p:
                return None
            try:
                return ctypes.wstring_at(p)
            finally:
                _k32.GlobalUnlock(h)
    except RuntimeError:
        return None


def set_clipboard_text(text: str) -> bool:
    """Set clipboard to text. Returns True on success."""
    try:
        with win32_clipboard() as u32:
            u32.EmptyClipboard()
            data = text.encode("utf-16-le") + b"\x00\x00"
            h = _k32.GlobalAlloc(0x0002, len(data))  # GMEM_MOVEABLE
            if not h:
                return False
            ptr = _k32.GlobalLock(h)
            if not ptr:
                _k32.GlobalFree(h)
                return False
            ctypes.memmove(ptr, data, len(data))
            _k32.GlobalUnlock(h)
            u32.SetClipboardData(CF_UNICODETEXT, h)
            return True
    except RuntimeError:
        return False
