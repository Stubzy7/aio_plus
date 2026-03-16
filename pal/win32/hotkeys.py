
import ctypes
import ctypes.wintypes as wt
import logging
import threading
import time
from collections import defaultdict

log = logging.getLogger(__name__)

# LRESULT must be pointer-sized (64-bit on x64) and accept plain int returns.
# c_ssize_t is pointer-sized and works with plain Python ints.
LRESULT = ctypes.c_ssize_t

user32 = ctypes.windll.user32
user32.CallNextHookEx.argtypes = [wt.HHOOK, ctypes.c_int, wt.WPARAM, wt.LPARAM]
user32.CallNextHookEx.restype = LRESULT
user32.SetWindowsHookExW.restype = wt.HHOOK
user32.GetForegroundWindow.restype = wt.HWND
user32.GetWindowTextW.argtypes = [wt.HWND, ctypes.c_wchar_p, ctypes.c_int]
user32.GetWindowTextW.restype = ctypes.c_int

WH_KEYBOARD_LL = 13
WH_MOUSE_LL = 14
WM_KEYDOWN = 0x0100
WM_KEYUP = 0x0101
WM_SYSKEYDOWN = 0x0104
WM_SYSKEYUP = 0x0105
WM_LBUTTONDOWN = 0x0201
WM_LBUTTONUP = 0x0202
WM_RBUTTONDOWN = 0x0204
WM_RBUTTONUP = 0x0205
WM_MBUTTONDOWN = 0x0207
WM_MBUTTONUP = 0x0208

LLKHF_INJECTED = 0x00000010
LLMHF_INJECTED = 0x00000001

MOUSE_VK_MAP = {
    WM_LBUTTONDOWN: 0x01, WM_LBUTTONUP: 0x01,
    WM_RBUTTONDOWN: 0x02, WM_RBUTTONUP: 0x02,
    WM_MBUTTONDOWN: 0x04, WM_MBUTTONUP: 0x04,
}
MOUSE_DOWN_MSGS = {WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN}

HOOKPROC = ctypes.CFUNCTYPE(LRESULT, ctypes.c_int, wt.WPARAM, wt.LPARAM)


class KBDLLHOOKSTRUCT(ctypes.Structure):
    _fields_ = [
        ("vkCode", wt.DWORD),
        ("scanCode", wt.DWORD),
        ("flags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class MSLLHOOKSTRUCT(ctypes.Structure):
    _fields_ = [
        ("pt", wt.POINT),
        ("mouseData", wt.DWORD),
        ("flags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class HotkeyManager:

    def __init__(self, root=None):
        self.root = root
        self._lock = threading.Lock()
        self._bindings: dict[int, list[dict]] = defaultdict(list)
        self._hook = None
        self._mouse_hook = None
        self._thread = None
        self._fg_thread = None
        self._running = False
        self._hook_proc_ref = None
        self._game_active = False
        self._keys_down: set[int] = set()

    def register(self, key: str, callback, suppress: bool = True,
                 passthrough: bool = False):
        from input.keyboard import _vk_from_name
        vk = _vk_from_name(key)
        if not vk:
            return
        with self._lock:
            self._bindings[vk] = [
                b for b in self._bindings[vk] if b["callback"] is not callback
            ]
            self._bindings[vk].append({
                "callback": callback,
                "suppress": suppress,
                "enabled": True,
                "passthrough": passthrough,
            })

    def unregister(self, key: str, callback=None):
        from input.keyboard import _vk_from_name
        vk = _vk_from_name(key)
        if not vk:
            return
        with self._lock:
            if callback is None:
                self._bindings.pop(vk, None)
            else:
                self._bindings[vk] = [
                    b for b in self._bindings[vk] if b["callback"] is not callback
                ]

    def enable(self, key: str, callback=None):
        self._set_enabled(key, True, callback)

    def disable(self, key: str, callback=None):
        self._set_enabled(key, False, callback)

    def _set_enabled(self, key: str, enabled: bool, callback=None):
        from input.keyboard import _vk_from_name
        vk = _vk_from_name(key)
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
        self._fg_thread = threading.Thread(target=self._fg_poll_thread, daemon=True)
        self._fg_thread.start()
        self._thread = threading.Thread(target=self._hook_thread, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False
        if self._thread and self._thread.is_alive():
            tid = self._thread.ident
            if tid:
                user32.PostThreadMessageW(tid, 0x0012, 0, 0)  # WM_QUIT
            self._thread.join(timeout=2)
        if self._hook:
            user32.UnhookWindowsHookEx(self._hook)
            self._hook = None
        if self._mouse_hook:
            user32.UnhookWindowsHookEx(self._mouse_hook)
            self._mouse_hook = None

    def _fg_poll_thread(self):
        # Polls foreground window every 50ms so the hook callback
        # stays free of Win32 calls and returns within the Windows timeout.
        buf = ctypes.create_unicode_buffer(256)
        while self._running:
            try:
                hwnd = user32.GetForegroundWindow()
                if hwnd:
                    user32.GetWindowTextW(hwnd, buf, 256)
                    title = buf.value
                    self._game_active = ("ArkAscended" in title
                                         or "GG AIO" in title)
                else:
                    self._game_active = False
            except Exception:
                self._game_active = False
            time.sleep(0.050)

    def _hook_thread(self):
        _PKBD = ctypes.POINTER(KBDLLHOOKSTRUCT)

        def _low_level_handler(nCode, wParam, lParam):
            try:
                if nCode < 0:
                    return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))

                if wParam not in (WM_KEYDOWN, WM_SYSKEYDOWN, WM_KEYUP, WM_SYSKEYUP):
                    return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))

                kb = ctypes.cast(lParam, _PKBD).contents
                vk = kb.vkCode

                bindings = self._bindings.get(vk)
                if not bindings:
                    return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))

                if kb.flags & LLKHF_INJECTED:
                    return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))

                if not self._game_active:
                    return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))

                with self._lock:
                    bindings = list(bindings)

                is_down = wParam in (WM_KEYDOWN, WM_SYSKEYDOWN)
                is_up = not is_down

                if is_down:
                    if vk in self._keys_down:
                        with self._lock:
                            for b in bindings:
                                if b["enabled"] and b["suppress"]:
                                    return 1
                        return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))
                    self._keys_down.add(vk)
                else:
                    self._keys_down.discard(vk)

                suppress = False

                for b in bindings:
                    if b["enabled"]:
                        if b["suppress"]:
                            suppress = True
                        if is_down:
                            if self.root:
                                self.root.after(0, b["callback"])
                            else:
                                try:
                                    b["callback"]()
                                except Exception:
                                    pass

                if suppress:
                    return 1

                return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))
            except Exception as e:
                import sys
                print(f"HOOK ERROR: {e}", file=sys.stderr, flush=True)
                return int(user32.CallNextHookEx(self._hook, nCode, wParam, lParam))

        _PMOUSE = ctypes.POINTER(MSLLHOOKSTRUCT)

        def _mouse_handler(nCode, wParam, lParam):
            try:
                if nCode < 0:
                    return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))

                vk = MOUSE_VK_MAP.get(wParam)
                if not vk:
                    return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))

                bindings = self._bindings.get(vk)
                if not bindings:
                    return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))

                ms = ctypes.cast(lParam, _PMOUSE).contents
                if ms.flags & LLMHF_INJECTED:
                    return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))

                if not self._game_active:
                    return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))

                with self._lock:
                    bindings = list(bindings)

                is_down = wParam in MOUSE_DOWN_MSGS

                if is_down:
                    if vk in self._keys_down:
                        return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))
                    self._keys_down.add(vk)
                else:
                    self._keys_down.discard(vk)

                suppress = False
                for b in bindings:
                    if b["enabled"]:
                        if b["suppress"]:
                            suppress = True
                        if is_down:
                            if self.root:
                                self.root.after(0, b["callback"])
                            else:
                                try:
                                    b["callback"]()
                                except Exception:
                                    pass

                if suppress:
                    return 1

                return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))
            except Exception as e:
                import sys
                print(f"MOUSE HOOK ERROR: {e}", file=sys.stderr, flush=True)
                return int(user32.CallNextHookEx(self._mouse_hook, nCode, wParam, lParam))

        self._hook_proc_ref = HOOKPROC(_low_level_handler)
        self._hook = user32.SetWindowsHookExW(
            WH_KEYBOARD_LL, self._hook_proc_ref, None, 0
        )

        self._mouse_proc_ref = HOOKPROC(_mouse_handler)
        self._mouse_hook = user32.SetWindowsHookExW(
            WH_MOUSE_LL, self._mouse_proc_ref, None, 0
        )

        msg = wt.MSG()
        while self._running:
            ret = user32.GetMessageW(ctypes.byref(msg), None, 0, 0)
            if ret <= 0:
                break
            user32.TranslateMessage(ctypes.byref(msg))
            user32.DispatchMessageW(ctypes.byref(msg))

        if self._hook:
            user32.UnhookWindowsHookEx(self._hook)
            self._hook = None
        if self._mouse_hook:
            user32.UnhookWindowsHookEx(self._mouse_hook)
            self._mouse_hook = None
