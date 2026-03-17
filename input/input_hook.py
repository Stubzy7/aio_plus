
import threading
import time
from pynput import keyboard as pynput_kb


class InputHook:

    def __init__(self, timeout: float = 10.0):
        self.timeout = timeout
        self.result_key: str | None = None
        self.result_vk: int | None = None
        self._event = threading.Event()
        self._listener = None

    def start(self):
        self.result_key = None
        self.result_vk = None
        self._event.clear()

        def on_press(key):
            try:
                if hasattr(key, "char") and key.char:
                    self.result_key = key.char
                elif hasattr(key, "name"):
                    self.result_key = key.name
                else:
                    self.result_key = str(key)

                if hasattr(key, "vk"):
                    self.result_vk = key.vk
                elif hasattr(key, "value") and hasattr(key.value, "vk"):
                    self.result_vk = key.value.vk
            except Exception:
                self.result_key = str(key)

            self._event.set()
            return False

        self._listener = pynput_kb.Listener(on_press=on_press)
        self._listener.start()

    def wait(self) -> str | None:
        self._event.wait(timeout=self.timeout)
        if self._listener:
            self._listener.stop()
        return self.result_key

    def stop(self):
        self._event.set()
        if self._listener:
            self._listener.stop()


class KeyRecorder:

    def __init__(self):
        self.events: list[dict] = []
        self._start_time = 0
        self._listener = None
        self._mouse_listener = None
        self._lock = threading.Lock()

    def start(self):
        self.events = []
        self._start_time = time.perf_counter()

        def on_key_press(key):
            self._log_key(key, "down")

        def on_key_release(key):
            self._log_key(key, "up")

        self._listener = pynput_kb.Listener(
            on_press=on_key_press,
            on_release=on_key_release,
        )
        self._listener.start()

    def _log_key(self, key, direction: str):
        elapsed_ms = int((time.perf_counter() - self._start_time) * 1000)
        name = ""
        try:
            if hasattr(key, "char") and key.char:
                name = key.char
            elif hasattr(key, "name"):
                name = key.name
            else:
                name = str(key)
        except Exception:
            name = str(key)

        with self._lock:
            self.events.append({
                "type": "K",
                "key": name,
                "direction": direction,
                "time": elapsed_ms,
            })

    def stop(self) -> list[dict]:
        if self._listener:
            self._listener.stop()
        with self._lock:
            return list(self.events)
