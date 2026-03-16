
import ctypes
import ctypes.wintypes as wt
import logging

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

log = logging.getLogger(__name__)

SW_RESTORE = 9
SW_SHOW = 5
GWL_STYLE = -16
WS_MINIMIZE = 0x20000000
SWP_NOSIZE = 0x0001
SWP_NOZORDER = 0x0004

# Window messages
WM_MOUSEMOVE = 0x0200
WM_LBUTTONDOWN = 0x0201
WM_LBUTTONUP = 0x0202
MK_LBUTTON = 0x0001

# Callback type for EnumChildWindows
WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)


def find_window(class_name: str | None = None,
                title: str | None = None) -> int:
    """Find a window by class name and/or title. Returns HWND or 0."""
    return user32.FindWindowW(class_name, title)


def win_exist(title: str) -> int:
    """Check if a window with the given title exists. Returns HWND or 0."""
    return user32.FindWindowW(None, title)


def win_activate(hwnd: int):
    """Bring a window to the foreground."""
    if user32.IsIconic(hwnd):
        user32.ShowWindow(hwnd, SW_RESTORE)
    user32.SetForegroundWindow(hwnd)


def win_get_pos(hwnd: int) -> tuple[int, int, int, int]:
    """Get window position and size. Returns (x, y, width, height)."""
    rect = wt.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    return (rect.left, rect.top,
            rect.right - rect.left,
            rect.bottom - rect.top)


def win_move(hwnd: int, x: int, y: int, w: int = 0, h: int = 0):
    """Move and optionally resize a window."""
    if w <= 0 or h <= 0:
        _, _, cw, ch = win_get_pos(hwnd)
        if w <= 0:
            w = cw
        if h <= 0:
            h = ch
    user32.MoveWindow(hwnd, x, y, w, h, True)


# ---------------------------------------------------------------------------
#  Child window detection
# ---------------------------------------------------------------------------

def _get_class_name(hwnd: int) -> str:
    """Get the window class name."""
    buf = ctypes.create_unicode_buffer(256)
    user32.GetClassNameW(hwnd, buf, 256)
    return buf.value


def find_input_child(hwnd: int) -> int:
    """Find the deepest child that covers the full client area.

    Some UE4/UE5 games have a top-level window with a child render surface.
    ControlClick targets the child, not the parent.  If no qualifying child
    is found, returns the original hwnd.
    """
    parent_rect = wt.RECT()
    user32.GetClientRect(hwnd, ctypes.byref(parent_rect))
    pw = parent_rect.right
    ph = parent_rect.bottom

    best = [hwnd]  # mutable so callback can write

    def _enum(child_hwnd, _lparam):
        child_rect = wt.RECT()
        user32.GetClientRect(child_hwnd, ctypes.byref(child_rect))
        cw = child_rect.right
        ch = child_rect.bottom
        cclass = _get_class_name(child_hwnd)
        log.debug("  child hwnd=%s class='%s' size=%dx%d", child_hwnd, cclass, cw, ch)
        # Child that fills (or nearly fills) the parent is the render surface
        if cw >= pw - 20 and ch >= ph - 20:
            best[0] = child_hwnd
        return True

    cb = WNDENUMPROC(_enum)
    user32.EnumChildWindows(hwnd, cb, 0)
    return best[0]


# ---------------------------------------------------------------------------
#  Background input via PostMessage
# ---------------------------------------------------------------------------
# ControlClick uses PostMessage to send WM_MOUSEMOVE + WM_LBUTTONDOWN +
# WM_LBUTTONUP — background, focus-independent clicking.

def control_click(hwnd: int, x: int, y: int):
    """Click at client (x, y) via PostMessage (background, focus-independent).

    Sends WM_MOUSEMOVE then WM_LBUTTONDOWN/UP.  Uses PostMessage (async)
    not SendMessage (blocking) to avoid deadlocking with DX render loops.
    """
    x, y = int(x), int(y)
    lparam = (y << 16) | (x & 0xFFFF)

    # Verify packing
    check_x = lparam & 0xFFFF
    check_y = (lparam >> 16) & 0xFFFF
    cname = _get_class_name(hwnd)
    log.debug("control_click: hwnd=%s class='%s' target=(%d,%d) packed=(%d,%d)",
              hwnd, cname, x, y, check_x, check_y)

    user32.PostMessageW(hwnd, WM_MOUSEMOVE, 0, lparam)
    user32.PostMessageW(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, lparam)
    user32.PostMessageW(hwnd, WM_LBUTTONUP, 0, lparam)


def get_client_rect(hwnd: int) -> tuple[int, int, int, int]:
    """Get client area rect. Returns (0, 0, width, height)."""
    rect = wt.RECT()
    user32.GetClientRect(hwnd, ctypes.byref(rect))
    return (rect.left, rect.top, rect.right, rect.bottom)


def is_window_visible(hwnd: int) -> bool:
    """Check if a window is visible."""
    return bool(user32.IsWindowVisible(hwnd))


def get_foreground_window() -> int:
    """Get the HWND of the currently focused window."""
    return user32.GetForegroundWindow()


# Keep for keyboard.py compatibility
def _flash_activate(hwnd: int) -> int:
    """Activate hwnd, return the previous foreground window."""
    prev = user32.GetForegroundWindow()
    if prev != hwnd:
        fg_tid = user32.GetWindowThreadProcessId(prev, None)
        our_tid = kernel32.GetCurrentThreadId()
        attached = False
        if fg_tid != our_tid:
            attached = bool(user32.AttachThreadInput(our_tid, fg_tid, True))
        try:
            user32.BringWindowToTop(hwnd)
            user32.SetForegroundWindow(hwnd)
        finally:
            if attached:
                user32.AttachThreadInput(our_tid, fg_tid, False)
        import time
        time.sleep(0.03)
    return prev


def _flash_restore(prev_hwnd: int, game_hwnd: int):
    """Restore the previous foreground window after input."""
    if prev_hwnd and prev_hwnd != game_hwnd:
        import time
        time.sleep(0.02)
        fg_tid = user32.GetWindowThreadProcessId(
            user32.GetForegroundWindow(), None)
        our_tid = kernel32.GetCurrentThreadId()
        attached = False
        if fg_tid != our_tid:
            attached = bool(user32.AttachThreadInput(our_tid, fg_tid, True))
        try:
            user32.BringWindowToTop(prev_hwnd)
            user32.SetForegroundWindow(prev_hwnd)
        finally:
            if attached:
                user32.AttachThreadInput(our_tid, fg_tid, False)
