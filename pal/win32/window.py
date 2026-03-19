
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

WM_MOUSEMOVE = 0x0200
WM_LBUTTONDOWN = 0x0201
WM_LBUTTONUP = 0x0202
MK_LBUTTON = 0x0001

WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)


def find_window(class_name: str | None = None,
                title: str | None = None) -> int:
    return user32.FindWindowW(class_name, title)


def win_exist(title: str) -> int:
    return user32.FindWindowW(None, title)


def win_activate(hwnd: int):
    if user32.IsIconic(hwnd):
        user32.ShowWindow(hwnd, SW_RESTORE)
    user32.SetForegroundWindow(hwnd)


def win_get_pos(hwnd: int) -> tuple[int, int, int, int]:
    rect = wt.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    return (rect.left, rect.top,
            rect.right - rect.left,
            rect.bottom - rect.top)


def win_move(hwnd: int, x: int, y: int, w: int = 0, h: int = 0):
    if w <= 0 or h <= 0:
        _, _, cw, ch = win_get_pos(hwnd)
        if w <= 0:
            w = cw
        if h <= 0:
            h = ch
    user32.MoveWindow(hwnd, x, y, w, h, True)


def _get_class_name(hwnd: int) -> str:
    buf = ctypes.create_unicode_buffer(256)
    user32.GetClassNameW(hwnd, buf, 256)
    return buf.value


def find_input_child(hwnd: int) -> int:
    # Some UE4/UE5 games have a child render surface that ControlClick
    # must target instead of the parent window.
    parent_rect = wt.RECT()
    user32.GetClientRect(hwnd, ctypes.byref(parent_rect))
    pw = parent_rect.right
    ph = parent_rect.bottom

    best = [hwnd]

    def _enum(child_hwnd, _lparam):
        child_rect = wt.RECT()
        user32.GetClientRect(child_hwnd, ctypes.byref(child_rect))
        cw = child_rect.right
        ch = child_rect.bottom
        cclass = _get_class_name(child_hwnd)
        log.debug("  child hwnd=%s class='%s' size=%dx%d", child_hwnd, cclass, cw, ch)
        if cw >= pw - 20 and ch >= ph - 20:
            best[0] = child_hwnd
        return True

    cb = WNDENUMPROC(_enum)
    user32.EnumChildWindows(hwnd, cb, 0)
    return best[0]


def control_click(hwnd: int, x: int, y: int, *, activate: bool = True):
    x, y = int(x), int(y)
    lparam = (y << 16) | (x & 0xFFFF)
    log.debug("control_click: hwnd=%s target=(%d,%d) activate=%s", hwnd, x, y, activate)

    needs_activate = activate and user32.GetForegroundWindow() != hwnd
    if needs_activate:
        prev = _flash_activate(hwnd)
        user32.PostMessageW(hwnd, WM_MOUSEMOVE, 0, lparam)

    user32.PostMessageW(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, lparam)
    user32.PostMessageW(hwnd, WM_LBUTTONUP, 0, lparam)

    if needs_activate:
        _flash_restore(prev, hwnd)


def get_client_rect(hwnd: int) -> tuple[int, int, int, int]:
    rect = wt.RECT()
    user32.GetClientRect(hwnd, ctypes.byref(rect))
    return (rect.left, rect.top, rect.right, rect.bottom)


def is_window_visible(hwnd: int) -> bool:
    return bool(user32.IsWindowVisible(hwnd))


def get_foreground_window() -> int:
    return user32.GetForegroundWindow()


def _flash_activate(hwnd: int) -> int:
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
