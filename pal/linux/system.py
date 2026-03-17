import fcntl
import os
import threading

from pynput import keyboard as pynput_kb

from .keyboard import VK_MAP


def acquire_mutex(name: str = "GG_AIO_MUTEX"):
    lock_path = f"/tmp/{name}.lock"
    try:
        lock_file = open(lock_path, "w")
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return lock_file, True
    except (IOError, OSError):
        return None, False


def release_mutex(mutex):
    if mutex is not None:
        try:
            fcntl.flock(mutex, fcntl.LOCK_UN)
            mutex.close()
        except Exception:
            pass


def message_box(text: str, title: str = "GG AIO", flags: int = 0x30):
    try:
        import tkinter as tk
        from tkinter import messagebox
        root = tk.Tk()
        root.withdraw()
        if flags & 0x10:
            messagebox.showerror(title, text)
        elif flags & 0x40:
            messagebox.showinfo(title, text)
        else:
            messagebox.showwarning(title, text)
        root.destroy()
    except Exception:
        print(f"[{title}] {text}")


def begin_timer_period(ms: int = 1):
    pass


def end_timer_period(ms: int = 1):
    pass


_pressed_keys: set[int] = set()
_lock = threading.Lock()
_listener: pynput_kb.Listener | None = None


def _key_to_vk(key) -> int:
    if isinstance(key, pynput_kb.Key):
        _SPECIAL = {
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
        return _SPECIAL.get(key, 0)

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


def _start_key_listener():
    global _listener
    if _listener is not None:
        return

    def on_press(key):
        vk = _key_to_vk(key)
        if vk:
            with _lock:
                _pressed_keys.add(vk)

    def on_release(key):
        vk = _key_to_vk(key)
        if vk:
            with _lock:
                _pressed_keys.discard(vk)

    _listener = pynput_kb.Listener(on_press=on_press, on_release=on_release)
    _listener.daemon = True
    _listener.start()


def get_async_key_state(vk: int) -> bool:
    _start_key_listener()
    with _lock:
        return vk in _pressed_keys
