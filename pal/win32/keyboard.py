
import ctypes
import ctypes.wintypes as wt
import time

user32 = ctypes.windll.user32

INPUT_KEYBOARD = 1
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_SCANCODE = 0x0008
KEYEVENTF_UNICODE = 0x0004
KEYEVENTF_EXTENDEDKEY = 0x0001

WM_KEYDOWN = 0x0100
WM_KEYUP = 0x0101
WM_CHAR = 0x0102

VK_MAP = {
    "enter": 0x0D, "return": 0x0D, "tab": 0x09, "escape": 0x1B, "esc": 0x1B,
    "space": 0x20, "backspace": 0x08, "delete": 0x2E, "insert": 0x2D,
    "home": 0x24, "end": 0x23, "pageup": 0x21, "pagedown": 0x22,
    "up": 0x26, "down": 0x28, "left": 0x25, "right": 0x27,
    "lshift": 0xA0, "rshift": 0xA1, "shift": 0x10,
    "lcontrol": 0xA2, "rcontrol": 0xA3, "control": 0x11, "ctrl": 0x11,
    "lalt": 0xA4, "ralt": 0xA5, "alt": 0x12,
    "lwin": 0x5B, "rwin": 0x5C,
    "capslock": 0x14, "numlock": 0x90, "scrolllock": 0x91,
    "f1": 0x70, "f2": 0x71, "f3": 0x72, "f4": 0x73,
    "f5": 0x74, "f6": 0x75, "f7": 0x76, "f8": 0x77,
    "f9": 0x78, "f10": 0x79, "f11": 0x7A, "f12": 0x7B,
    "numpad0": 0x60, "numpad1": 0x61, "numpad2": 0x62, "numpad3": 0x63,
    "numpad4": 0x64, "numpad5": 0x65, "numpad6": 0x66, "numpad7": 0x67,
    "numpad8": 0x68, "numpad9": 0x69,
    "numpadadd": 0x6B, "numpadsub": 0x6D, "numpadmult": 0x6A,
    "numpaddiv": 0x6E, "numpaddot": 0x6E,
    "a": 0x41, "b": 0x42, "c": 0x43, "d": 0x44, "e": 0x45,
    "f": 0x46, "g": 0x47, "h": 0x48, "i": 0x49, "j": 0x4A,
    "k": 0x4B, "l": 0x4C, "m": 0x4D, "n": 0x4E, "o": 0x4F,
    "p": 0x50, "q": 0x51, "r": 0x52, "s": 0x53, "t": 0x54,
    "u": 0x55, "v": 0x56, "w": 0x57, "x": 0x58, "y": 0x59, "z": 0x5A,
    "0": 0x30, "1": 0x31, "2": 0x32, "3": 0x33, "4": 0x34,
    "5": 0x35, "6": 0x36, "7": 0x37, "8": 0x38, "9": 0x39,
    ";": 0xBA, "=": 0xBB, ",": 0xBC, "-": 0xBD, ".": 0xBE,
    "/": 0xBF, "`": 0xC0, "[": 0xDB, "\\": 0xDC, "]": 0xDD, "'": 0xDE,
    "vkc0": 0xC0,
    "lbutton": 0x01, "rbutton": 0x02, "mbutton": 0x04,
}

EXTENDED_KEYS = {
    0x2D, 0x2E, 0x24, 0x23, 0x21, 0x22,
    0x25, 0x26, 0x27, 0x28,
    0x5B, 0x5C,
    0xA3, 0xA5,
}


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [
        ("wVk", wt.WORD),
        ("wScan", wt.WORD),
        ("dwFlags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [
        ("dx", wt.LONG), ("dy", wt.LONG), ("mouseData", wt.DWORD),
        ("dwFlags", wt.DWORD), ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [
        ("uMsg", wt.DWORD), ("wParamL", wt.WORD), ("wParamH", wt.WORD),
    ]


class INPUT_UNION(ctypes.Union):
    _fields_ = [("ki", KEYBDINPUT), ("mi", MOUSEINPUT), ("hi", HARDWAREINPUT)]


class INPUT(ctypes.Structure):
    _fields_ = [("type", wt.DWORD), ("union", INPUT_UNION)]


def _send_input(*inputs: INPUT):
    n = len(inputs)
    arr = (INPUT * n)(*inputs)
    user32.SendInput(n, ctypes.byref(arr), ctypes.sizeof(INPUT))


def _vk_from_name(name: str) -> int:
    lower = name.lower().strip("{}")
    if lower in VK_MAP:
        return VK_MAP[lower]
    if len(lower) == 1:
        return user32.VkKeyScanW(ord(lower)) & 0xFF
    if lower.startswith("vk"):
        try:
            return int(lower[2:], 16)
        except ValueError:
            pass
    return 0


def _make_key_input(vk: int, up: bool = False) -> INPUT:
    # Sends wVk + wScan together WITHOUT KEYEVENTF_SCANCODE so both
    # Windows (VK) and DirectInput (scancode) see the key.
    inp = INPUT()
    inp.type = INPUT_KEYBOARD
    inp.union.ki.wVk = vk
    inp.union.ki.wScan = user32.MapVirtualKeyW(vk, 0)
    flags = 0
    if up:
        flags |= KEYEVENTF_KEYUP
    if vk in EXTENDED_KEYS:
        flags |= KEYEVENTF_EXTENDEDKEY
    inp.union.ki.dwFlags = flags
    return inp


def key_down(key: str):
    vk = _vk_from_name(key)
    if vk:
        _send_input(_make_key_input(vk, up=False))


def key_up(key: str):
    vk = _vk_from_name(key)
    if vk:
        _send_input(_make_key_input(vk, up=True))


def key_press(key: str, duration_ms: int = 0):
    vk = _vk_from_name(key)
    if vk:
        if duration_ms > 0:
            _send_input(_make_key_input(vk, up=False))
            time.sleep(duration_ms / 1000.0)
            _send_input(_make_key_input(vk, up=True))
        else:
            _send_input(_make_key_input(vk, up=False),
                        _make_key_input(vk, up=True))


def send(keys: str):
    i = 0
    while i < len(keys):
        ch = keys[i]

        if ch == "^":
            key_down("ctrl")
            i += 1
            if i < len(keys):
                _send_one_char_or_brace(keys, i)
                i = _skip_one(keys, i)
            key_up("ctrl")
            continue
        if ch == "+":
            key_down("shift")
            i += 1
            if i < len(keys):
                _send_one_char_or_brace(keys, i)
                i = _skip_one(keys, i)
            key_up("shift")
            continue
        if ch == "!":
            key_down("alt")
            i += 1
            if i < len(keys):
                _send_one_char_or_brace(keys, i)
                i = _skip_one(keys, i)
            key_up("alt")
            continue

        if ch == "{":
            end = keys.find("}", i + 1)
            if end != -1:
                key_name = keys[i + 1:end]
                parts = key_name.rsplit(" ", 1)
                if len(parts) == 2 and parts[1].isdigit():
                    for _ in range(int(parts[1])):
                        key_press(parts[0])
                else:
                    key_press(key_name)
                i = end + 1
                continue

        key_press(ch)
        i += 1


def _send_one_char_or_brace(keys: str, i: int):
    if keys[i] == "{":
        end = keys.find("}", i + 1)
        if end != -1:
            key_press(keys[i + 1:end])
    else:
        key_press(keys[i])


def _skip_one(keys: str, i: int) -> int:
    if i < len(keys) and keys[i] == "{":
        end = keys.find("}", i + 1)
        return end + 1 if end != -1 else i + 1
    return i + 1


def _type_char(ch: str):
    inp_down = INPUT()
    inp_down.type = INPUT_KEYBOARD
    inp_down.union.ki.wScan = ord(ch)
    inp_down.union.ki.dwFlags = KEYEVENTF_UNICODE

    inp_up = INPUT()
    inp_up.type = INPUT_KEYBOARD
    inp_up.union.ki.wScan = ord(ch)
    inp_up.union.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP

    _send_input(inp_down, inp_up)


def send_text(text: str):
    # NOTE: ARK/Unreal ignores KEYEVENTF_UNICODE input.
    # Use send_text_vk() for games requiring VK-based input.
    for ch in text:
        _type_char(ch)
        time.sleep(0.001)


def send_text_vk(text: str):
    for ch in text:
        key_press(ch)
        time.sleep(0.001)


def _make_lparam(vk: int, up: bool = False) -> int:
    scan = user32.MapVirtualKeyW(vk, 0) & 0xFF
    lparam = 1 | (scan << 16)
    if vk in EXTENDED_KEYS:
        lparam |= (1 << 24)
    if up:
        lparam |= (1 << 30) | (1 << 31)
    return lparam


def _send_key_input(vk: int, up: bool = False):
    scan = user32.MapVirtualKeyW(vk, 0) & 0xFF
    flags = KEYEVENTF_SCANCODE
    if vk in EXTENDED_KEYS:
        flags |= KEYEVENTF_EXTENDEDKEY
    if up:
        flags |= KEYEVENTF_KEYUP

    inp = INPUT()
    inp.type = INPUT_KEYBOARD
    inp.union.ki.wVk = vk
    inp.union.ki.wScan = scan
    inp.union.ki.dwFlags = flags
    arr = (INPUT * 1)(inp)
    user32.SendInput(1, arr, ctypes.sizeof(INPUT))


def control_send(hwnd: int, keys: str):
    _post = user32.PostMessageW
    i = 0
    while i < len(keys):
        ch = keys[i]

        if ch in "^+!":
            mod_vk = {'^': 0x11, '+': 0x10, '!': 0x12}[ch]
            i += 1
            if i >= len(keys):
                break
            next_ch = keys[i]
            vk = VK_MAP.get(next_ch.lower())
            if not vk:
                vk = ord(next_ch.upper()) if next_ch.isalpha() else ord(next_ch)
            _post(hwnd, WM_KEYDOWN, mod_vk, _make_lparam(mod_vk))
            _post(hwnd, WM_KEYDOWN, vk, _make_lparam(vk))
            _post(hwnd, WM_KEYUP, vk, _make_lparam(vk, up=True))
            _post(hwnd, WM_KEYUP, mod_vk, _make_lparam(mod_vk, up=True))
            i += 1
            continue

        if ch == '{':
            close = keys.find('}', i + 1)
            if close == -1:
                i += 1
                continue
            raw = keys[i + 1:close]
            parts = raw.lower().split()
            if len(parts) == 2 and parts[1] in ("down", "up"):
                vk = VK_MAP.get(parts[0])
                if vk:
                    if parts[1] == "down":
                        _post(hwnd, WM_KEYDOWN, vk, _make_lparam(vk))
                    else:
                        _post(hwnd, WM_KEYUP, vk, _make_lparam(vk, up=True))
            else:
                vk = VK_MAP.get(raw.lower())
                if vk:
                    _post(hwnd, WM_KEYDOWN, vk, _make_lparam(vk))
                    _post(hwnd, WM_KEYUP, vk, _make_lparam(vk, up=True))
            i = close + 1
            continue

        vk = VK_MAP.get(ch.lower())
        if vk:
            _post(hwnd, WM_KEYDOWN, vk, _make_lparam(vk))
            _post(hwnd, WM_CHAR, ord(ch), _make_lparam(vk))
            _post(hwnd, WM_KEYUP, vk, _make_lparam(vk, up=True))
        else:
            _post(hwnd, WM_CHAR, ord(ch), 0)
        i += 1


def control_send_text(hwnd: int, text: str):
    for ch in text:
        user32.PostMessageW(hwnd, WM_CHAR, ord(ch), 0)
