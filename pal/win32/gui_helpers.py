import ctypes
import ctypes.wintypes as wt

GWL_EXSTYLE = -20
WS_EX_NOACTIVATE = 0x08000000
WS_EX_TOOLWINDOW = 0x00000080

_user32 = ctypes.windll.user32

def set_no_activate(hwnd_hex_str: str):
    try:
        hwnd = int(hwnd_hex_str, 16)
        style = _user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
        _user32.SetWindowLongW(hwnd, GWL_EXSTYLE, style | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW)
    except Exception:
        pass

def flash_activate(hwnd: int) -> int:
    import time
    prev = _user32.GetForegroundWindow()
    if prev != hwnd:
        fg_tid = _user32.GetWindowThreadProcessId(prev, None)
        our_tid = ctypes.windll.kernel32.GetCurrentThreadId()
        attached = False
        if fg_tid != our_tid:
            attached = bool(_user32.AttachThreadInput(our_tid, fg_tid, True))
        try:
            _user32.BringWindowToTop(hwnd)
            _user32.SetForegroundWindow(hwnd)
        finally:
            if attached:
                _user32.AttachThreadInput(our_tid, fg_tid, False)
        time.sleep(0.03)
    return prev

def flash_restore(prev_hwnd: int, game_hwnd: int):
    import time
    if prev_hwnd and prev_hwnd != game_hwnd:
        time.sleep(0.02)
        fg_tid = _user32.GetWindowThreadProcessId(_user32.GetForegroundWindow(), None)
        our_tid = ctypes.windll.kernel32.GetCurrentThreadId()
        attached = False
        if fg_tid != our_tid:
            attached = bool(_user32.AttachThreadInput(our_tid, fg_tid, True))
        try:
            _user32.BringWindowToTop(prev_hwnd)
            _user32.SetForegroundWindow(prev_hwnd)
        finally:
            if attached:
                _user32.AttachThreadInput(our_tid, fg_tid, False)
