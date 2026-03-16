
import threading
import time


class TimerManager:
    """Manage named periodic timers."""

    def __init__(self):
        self._timers: dict[str, dict] = {}
        self._lock = threading.Lock()

    def set_timer(self, name: str, callback, period_ms: int):
        """Set a timer.

        Args:
            name: Unique identifier for this timer.
            callback: Function to call.
            period_ms: Positive = recurring, negative = one-shot, 0 = stop.
        """
        self.stop_timer(name)

        if period_ms == 0:
            return

        one_shot = period_ms < 0
        interval = abs(period_ms) / 1000.0

        entry = {
            "callback": callback,
            "interval": interval,
            "one_shot": one_shot,
            "running": True,
            "thread": None,
        }

        def _run():
            while entry["running"]:
                time.sleep(entry["interval"])
                if not entry["running"]:
                    break
                try:
                    callback()
                except Exception:
                    pass
                if one_shot:
                    entry["running"] = False
                    break

        t = threading.Thread(target=_run, daemon=True)
        entry["thread"] = t

        with self._lock:
            self._timers[name] = entry

        t.start()

    def stop_timer(self, name: str):
        """Stop a timer by name."""
        with self._lock:
            entry = self._timers.pop(name, None)
        if entry:
            entry["running"] = False

    def stop_all(self):
        """Stop all timers."""
        with self._lock:
            names = list(self._timers.keys())
        for name in names:
            self.stop_timer(name)

    def is_running(self, name: str) -> bool:
        """Check if a timer is currently running."""
        with self._lock:
            entry = self._timers.get(name)
            return entry is not None and entry["running"]


# Singleton
timers = TimerManager()
