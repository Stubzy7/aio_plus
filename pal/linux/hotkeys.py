import subprocess
import threading
import time

from pynput import keyboard as pynput_kb

from .keyboard import VK_MAP


_VK_REVERSE = {}
for _name, _vk in VK_MAP.items():
    if _vk not in _VK_REVERSE:
        _VK_REVERSE[_vk] = _name


def _pynput_key_to_vk(key) -> int:
    if isinstance(key, pynput_kb.Key):
        _SPECIAL_MAP = {
            pynput_kb.Key.enter: 0x0D,
            pynput_kb.Key.tab: 0x09,
            pynput_kb.Key.esc: 0x1B,
            pynput_kb.Key.space: 0x20,
            pynput_kb.Key.backspace: 0x08,
            pynput_kb.Key.delete: 0x2E,
            pynput_kb.Key.insert: 0x2D,
            pynput_kb.Key.home: 0x24,
            pynput_kb.Key.end: 0x23,
            pynput_kb.Key.page_up: 0x21,
            pynput_kb.Key.page_down: 0x22,
            pynput_kb.Key.up: 0x26,
            pynput_kb.Key.down: 0x28,
            pynput_kb.Key.left: 0x25,
            pynput_kb.Key.right: 0x27,
            pynput_kb.Key.shift_l: 0xA0,
            pynput_kb.Key.shift_r: 0xA1,
            pynput_kb.Key.shift: 0x10,
            pynput_kb.Key.ctrl_l: 0xA2,
            pynput_kb.Key.ctrl_r: 0xA3,
            pynput_kb.Key.ctrl: 0x11,
            pynput_kb.Key.alt_l: 0xA4,
            pynput_kb.Key.alt_r: 0xA5,
            pynput_kb.Key.alt: 0x12,
            pynput_kb.Key.caps_lock: 0x14,
            pynput_kb.Key.num_lock: 0x90,
            pynput_kb.Key.scroll_lock: 0x91,
            pynput_kb.Key.f1: 0x70,
            pynput_kb.Key.f2: 0x71,
            pynput_kb.Key.f3: 0x72,
            pynput_kb.Key.f4: 0x73,
            pynput_kb.Key.f5: 0x74,
            pynput_kb.Key.f6: 0x75,
            pynput_kb.Key.f7: 0x76,
            pynput_kb.Key.f8: 0x77,
            pynput_kb.Key.f9: 0x78,
            pynput_kb.Key.f10: 0x79,
            pynput_kb.Key.f11: 0x7A,
            pynput_kb.Key.f12: 0x7B,
        }
        return _SPECIAL_MAP.get(key, 0)

    if isinstance(key, pynput_kb.KeyCode):
        if key.vk is not None:
            return key.vk
        if key.char is not None:
            c = key.char.lower()
            if c in VK_MAP:
                return VK_MAP[c]
            o = ord(c)
            if ord('a') <= o <= ord('z'):
                return o - 32
            if ord('0') <= o <= ord('9'):
                return o
    return 0


def _get_active_window_name() -> str:
    try:
        result = subprocess.run(
            ["xdotool", "getactivewindow", "getwindowname"],
            capture_output=True, text=True, timeout=2
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""


class HotkeyManager:

    def __init__(self, root=None):
        self.root = root
        self._bindings: dict[int, list[dict]] = {}
        self._listener: pynput_kb.Listener | None = None
        self._lock = threading.Lock()
        self._running = False
        self._game_active = False
        self._fg_thread = None
        self._keys_down: set[int] = set()

    def register(self, key: str, callback, suppress: bool = True,
                 passthrough: bool = False):
        lower = key.lower().strip("{}")
        vk = VK_MAP.get(lower, 0)
        if not vk:
            return

        entry = {
            "callback": callback,
            "suppress": suppress,
            "passthrough": passthrough,
            "enabled": True,
            "key_name": key,
        }
        with self._lock:
            if vk not in self._bindings:
                self._bindings[vk] = []
            self._bindings[vk].append(entry)

    def unregister(self, key: str, callback=None):
        lower = key.lower().strip("{}")
        vk = VK_MAP.get(lower, 0)
        if not vk:
            return

        with self._lock:
            if vk not in self._bindings:
                return
            if callback is None:
                del self._bindings[vk]
            else:
                self._bindings[vk] = [
                    b for b in self._bindings[vk]
                    if b["callback"] is not callback
                ]
                if not self._bindings[vk]:
                    del self._bindings[vk]

    def enable(self, key: str, callback=None):
        self._set_enabled(key, callback, True)

    def disable(self, key: str, callback=None):
        self._set_enabled(key, callback, False)

    def _set_enabled(self, key: str, callback, enabled: bool):
        lower = key.lower().strip("{}")
        vk = VK_MAP.get(lower, 0)
        if not vk:
            return
        with self._lock:
            for b in self._bindings.get(vk, []):
                if callback is None or b["callback"] is callback:
                    b["enabled"] = enabled

    def start(self):
        if self._running:
            return
        self._running = True

        needs_suppress = any(
            b["suppress"]
            for bindings in self._bindings.values()
            for b in bindings
        )

        self._listener = pynput_kb.Listener(
            on_press=self._on_press,
            on_release=self._on_release,
            suppress=needs_suppress,
        )
        self._listener.daemon = True
        self._listener.start()

        self._fg_thread = threading.Thread(target=self._poll_game_active, daemon=True)
        self._fg_thread.start()

    def stop(self):
        self._running = False
        if self._listener:
            self._listener.stop()
            self._listener = None

    def _poll_game_active(self):
        import subprocess
        while self._running:
            try:
                result = subprocess.run(
                    ["xdotool", "getactivewindow", "getwindowname"],
                    capture_output=True, text=True, timeout=1
                )
                title = result.stdout.strip()
                self._game_active = ("ArkAscended" in title or "GG AIO" in title)
            except Exception:
                self._game_active = False
            time.sleep(0.050)

    def _on_press(self, key):
        if not self._game_active:
            return

        vk = _pynput_key_to_vk(key)
        if not vk:
            return

        if vk in self._keys_down:
            return
        self._keys_down.add(vk)

        with self._lock:
            bindings = list(self._bindings.get(vk, []))

        for b in bindings:
            if not b["enabled"]:
                continue
            if self.root:
                self.root.after(0, b["callback"])
            else:
                try:
                    b["callback"]()
                except Exception:
                    pass

    def _on_release(self, key):
        vk = _pynput_key_to_vk(key)
        if vk:
            self._keys_down.discard(vk)
