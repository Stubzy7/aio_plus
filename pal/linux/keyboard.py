"""Linux keyboard input using xdotool.

Drop-in replacement for platform.win32.keyboard — same public API.
"""

import subprocess
import time

# Same VK_MAP as Windows — these are logical codes used throughout the app
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
}

# Extended keys (same set as Windows — used by some callers for key flag checks)
EXTENDED_KEYS = {
    0x2D, 0x2E, 0x24, 0x23, 0x21, 0x22,  # insert, delete, home, end, pgup, pgdn
    0x25, 0x26, 0x27, 0x28,  # arrow keys
    0x5B, 0x5C,  # win keys
    0xA3, 0xA5,  # right ctrl, right alt
}

# Map VK codes to xdotool key names
VK_TO_XDO = {
    0x0D: "Return", 0x09: "Tab", 0x1B: "Escape", 0x20: "space",
    0x08: "BackSpace", 0x2E: "Delete", 0x2D: "Insert",
    0x24: "Home", 0x23: "End", 0x21: "Prior", 0x22: "Next",
    0x26: "Up", 0x28: "Down", 0x25: "Left", 0x27: "Right",
    0xA0: "Shift_L", 0xA1: "Shift_R", 0x10: "Shift_L",
    0xA2: "Control_L", 0xA3: "Control_R", 0x11: "Control_L",
    0xA4: "Alt_L", 0xA5: "Alt_R", 0x12: "Alt_L",
    0x5B: "Super_L", 0x5C: "Super_R",
    0x14: "Caps_Lock", 0x90: "Num_Lock", 0x91: "Scroll_Lock",
    0xBA: "semicolon", 0xBB: "equal", 0xBC: "comma", 0xBD: "minus",
    0xBE: "period", 0xBF: "slash", 0xC0: "grave",
    0xDB: "bracketleft", 0xDC: "backslash", 0xDD: "bracketright", 0xDE: "apostrophe",
}
# F keys
for _i in range(12):
    VK_TO_XDO[0x70 + _i] = f"F{_i + 1}"
# Letters
for _i in range(26):
    VK_TO_XDO[0x41 + _i] = chr(ord('a') + _i)
# Digits
for _i in range(10):
    VK_TO_XDO[0x30 + _i] = str(_i)
# Numpad
for _i in range(10):
    VK_TO_XDO[0x60 + _i] = f"KP_{_i}"


def _vk_from_name(name: str) -> int:
    """Resolve a key name to a virtual key code."""
    lower = name.lower().strip("{}")
    if lower in VK_MAP:
        return VK_MAP[lower]
    # Single character
    if len(lower) == 1:
        c = ord(lower)
        if ord('a') <= c <= ord('z'):
            return c - 32  # to uppercase VK
        if ord('0') <= c <= ord('9'):
            return c
    # Hex vk code like vkC0
    if lower.startswith("vk"):
        try:
            return int(lower[2:], 16)
        except ValueError:
            pass
    return 0


def _vk_to_xdo(vk: int) -> str:
    """Convert a VK code to an xdotool key name."""
    return VK_TO_XDO.get(vk, "")


def _xdo(*args: str):
    """Run an xdotool command silently."""
    try:
        subprocess.run(["xdotool"] + list(args),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=5)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass


def key_down(key: str):
    """Press a key down (no release)."""
    vk = _vk_from_name(key)
    xdo_name = _vk_to_xdo(vk)
    if xdo_name:
        _xdo("keydown", xdo_name)


def key_up(key: str):
    """Release a key."""
    vk = _vk_from_name(key)
    xdo_name = _vk_to_xdo(vk)
    if xdo_name:
        _xdo("keyup", xdo_name)


def key_press(key: str, duration_ms: int = 0):
    """Press and release a key."""
    vk = _vk_from_name(key)
    xdo_name = _vk_to_xdo(vk)
    if not xdo_name:
        return
    if duration_ms > 0:
        _xdo("keydown", xdo_name)
        time.sleep(duration_ms / 1000.0)
        _xdo("keyup", xdo_name)
    else:
        _xdo("key", xdo_name)


def send(keys: str):
    """Parse and send a key string.

    Supports:
    - {key} for special keys: {Enter}, {Escape}, {F1}, etc.
    - ^ for Ctrl, + for Shift, ! for Alt
    - Plain characters are typed directly
    """
    i = 0
    while i < len(keys):
        ch = keys[i]

        # Modifier prefixes
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

        # Braced key name
        if ch == "{":
            end = keys.find("}", i + 1)
            if end != -1:
                key_name = keys[i + 1:end]
                # Handle {key N} for repeated presses
                parts = key_name.rsplit(" ", 1)
                if len(parts) == 2 and parts[1].isdigit():
                    for _ in range(int(parts[1])):
                        key_press(parts[0])
                else:
                    key_press(key_name)
                i = end + 1
                continue

        # Plain character
        key_press(ch)
        i += 1


def _send_one_char_or_brace(keys: str, i: int):
    """Send a single char or braced key starting at position i."""
    if keys[i] == "{":
        end = keys.find("}", i + 1)
        if end != -1:
            key_press(keys[i + 1:end])
    else:
        key_press(keys[i])


def _skip_one(keys: str, i: int) -> int:
    """Skip past one char or braced key."""
    if i < len(keys) and keys[i] == "{":
        end = keys.find("}", i + 1)
        return end + 1 if end != -1 else i + 1
    return i + 1


def send_text(text: str):
    """Type a string of text using xdotool type."""
    try:
        subprocess.run(["xdotool", "type", "--clearmodifiers", text],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=10)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass


def send_text_vk(text: str):
    """Type a string using individual key presses (VK-based)."""
    for ch in text:
        key_press(ch)
        time.sleep(0.001)


def _make_lparam(vk: int, up: bool = False) -> int:
    """Not needed on Linux. Returns 0 for API compatibility."""
    return 0


def control_send(hwnd: int, keys: str):
    """Send keys to a specific window via xdotool --window."""
    # Parse the key string and send each key with --window
    i = 0
    while i < len(keys):
        ch = keys[i]

        # Modifier prefixes
        if ch in "^+!":
            mod_map = {'^': "Control_L", '+': "Shift_L", '!': "Alt_L"}
            mod_xdo = mod_map[ch]
            i += 1
            if i >= len(keys):
                break
            next_ch = keys[i]
            if next_ch == "{":
                end = keys.find("}", i + 1)
                if end != -1:
                    key_name = keys[i + 1:end]
                    vk = _vk_from_name(key_name)
                    xdo_name = _vk_to_xdo(vk)
                    if xdo_name:
                        _xdo("key", "--window", str(hwnd),
                             f"{mod_xdo}+{xdo_name}")
                    i = end + 1
                else:
                    i += 1
            else:
                vk = _vk_from_name(next_ch)
                xdo_name = _vk_to_xdo(vk)
                if xdo_name:
                    _xdo("key", "--window", str(hwnd),
                         f"{mod_xdo}+{xdo_name}")
                i += 1
            continue

        # Brace-wrapped key name
        if ch == "{":
            close = keys.find("}", i + 1)
            if close == -1:
                i += 1
                continue
            raw = keys[i + 1:close]
            parts = raw.lower().split()
            # Handle {Ctrl down}, {Ctrl up}, etc.
            if len(parts) == 2 and parts[1] in ("down", "up"):
                vk = _vk_from_name(parts[0])
                xdo_name = _vk_to_xdo(vk)
                if xdo_name:
                    action = "keydown" if parts[1] == "down" else "keyup"
                    _xdo(action, "--window", str(hwnd), xdo_name)
            else:
                vk = _vk_from_name(raw)
                xdo_name = _vk_to_xdo(vk)
                if xdo_name:
                    _xdo("key", "--window", str(hwnd), xdo_name)
            i = close + 1
            continue

        # Plain character
        vk = _vk_from_name(ch)
        xdo_name = _vk_to_xdo(vk)
        if xdo_name:
            _xdo("key", "--window", str(hwnd), xdo_name)
        i += 1


def control_send_text(hwnd: int, text: str):
    """Send text to a specific window via xdotool type --window."""
    try:
        subprocess.run(["xdotool", "type", "--window", str(hwnd),
                        "--clearmodifiers", text],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=10)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
