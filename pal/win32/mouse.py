
import ctypes
import ctypes.wintypes as wt
import time

user32 = ctypes.windll.user32

# Input type constants
INPUT_MOUSE = 0
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_MIDDLEDOWN = 0x0020
MOUSEEVENTF_MIDDLEUP = 0x0040
MOUSEEVENTF_ABSOLUTE = 0x8000


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [
        ("dx", wt.LONG),
        ("dy", wt.LONG),
        ("mouseData", wt.DWORD),
        ("dwFlags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [
        ("wVk", wt.WORD),
        ("wScan", wt.WORD),
        ("dwFlags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [
        ("uMsg", wt.DWORD),
        ("wParamL", wt.WORD),
        ("wParamH", wt.WORD),
    ]


class INPUT_UNION(ctypes.Union):
    _fields_ = [
        ("mi", MOUSEINPUT),
        ("ki", KEYBDINPUT),
        ("hi", HARDWAREINPUT),
    ]


class INPUT(ctypes.Structure):
    _fields_ = [
        ("type", wt.DWORD),
        ("union", INPUT_UNION),
    ]


def _send_input(*inputs: INPUT):
    """Send one or more INPUT structs via SendInput."""
    n = len(inputs)
    arr = (INPUT * n)(*inputs)
    user32.SendInput(n, ctypes.byref(arr), ctypes.sizeof(INPUT))


def set_cursor_pos(x: int, y: int):
    """Move cursor to absolute screen coordinates (instant)."""
    user32.SetCursorPos(int(x), int(y))


def mouse_move(x: int, y: int, speed: int = 0):
    """Move mouse to (x, y). speed=0 is instant, higher values interpolate."""
    if speed <= 0:
        set_cursor_pos(x, y)
        return

    # Interpolated movement
    pt = wt.POINT()
    user32.GetCursorPos(ctypes.byref(pt))
    start_x, start_y = pt.x, pt.y
    dist_x = x - start_x
    dist_y = y - start_y
    steps = max(abs(dist_x), abs(dist_y)) // max(speed, 1)
    steps = max(steps, 1)

    for i in range(1, steps + 1):
        frac = i / steps
        cx = int(start_x + dist_x * frac)
        cy = int(start_y + dist_y * frac)
        set_cursor_pos(cx, cy)
        time.sleep(0.001)


def click(x: int | None = None, y: int | None = None, button: str = "left",
          count: int = 1):
    """Click at (x, y) or at current cursor position if coords are None."""
    if x is not None and y is not None:
        set_cursor_pos(int(x), int(y))
        time.sleep(0.001)

    if button == "left":
        down_flag = MOUSEEVENTF_LEFTDOWN
        up_flag = MOUSEEVENTF_LEFTUP
    elif button == "right":
        down_flag = MOUSEEVENTF_RIGHTDOWN
        up_flag = MOUSEEVENTF_RIGHTUP
    elif button == "middle":
        down_flag = MOUSEEVENTF_MIDDLEDOWN
        up_flag = MOUSEEVENTF_MIDDLEUP
    else:
        down_flag = MOUSEEVENTF_LEFTDOWN
        up_flag = MOUSEEVENTF_LEFTUP

    inp_down = INPUT()
    inp_down.type = INPUT_MOUSE
    inp_down.union.mi.dwFlags = down_flag

    inp_up = INPUT()
    inp_up.type = INPUT_MOUSE
    inp_up.union.mi.dwFlags = up_flag

    for _ in range(count):
        _send_input(inp_down, inp_up)


def mouse_down(button: str = "left"):
    """Press and hold a mouse button."""
    if button == "left":
        flag = MOUSEEVENTF_LEFTDOWN
    elif button == "right":
        flag = MOUSEEVENTF_RIGHTDOWN
    else:
        flag = MOUSEEVENTF_MIDDLEDOWN
    inp = INPUT()
    inp.type = INPUT_MOUSE
    inp.union.mi.dwFlags = flag
    _send_input(inp)


def mouse_up(button: str = "left"):
    """Release a mouse button."""
    if button == "left":
        flag = MOUSEEVENTF_LEFTUP
    elif button == "right":
        flag = MOUSEEVENTF_RIGHTUP
    else:
        flag = MOUSEEVENTF_MIDDLEUP
    inp = INPUT()
    inp.type = INPUT_MOUSE
    inp.union.mi.dwFlags = flag
    _send_input(inp)


def get_cursor_pos() -> tuple[int, int]:
    """Get current cursor position."""
    pt = wt.POINT()
    user32.GetCursorPos(ctypes.byref(pt))
    return (pt.x, pt.y)
